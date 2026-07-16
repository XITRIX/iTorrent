//
//  RendererRouteMenuView.swift
//  iTorrent
//

import SwiftUI
import SwiftVLC

struct RendererRouteMenuView: View {
    let player: Player

    @State private var services: [RendererService] = []
    @State private var discoverers: [RendererDiscoverer] = []
    @State private var observationTasks: [Task<Void, Never>] = []
    @State private var renderers: [RendererItem] = []
    @State private var selectedRendererID: RendererItem.ID?
    @State private var isRecasting = false
    @State private var statusMessage: String?

    var body: some View {
        Menu {
            Section("Play on") {
                Button {
                    recast(to: nil)
                } label: {
                    Label("This Device", systemImage: selectedRendererID == nil ? "checkmark" : "iphone")
                }
                .disabled(isRecasting)

//            if !services.isEmpty {
//                Section("Discovery") {
//                    ForEach(services, id: \.name) { service in
//                        Label(service.longName, systemImage: "network")
//                    }
//                }
//            }

                ForEach(renderers) { renderer in
                    Button {
                        recast(to: renderer)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(renderer.name)
                                Text(renderer.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: selectedRendererID == renderer.id ? "checkmark" : "tv")
                        }
                    }
                    .disabled(isRecasting || !renderer.canVideo)
                }
                Text(statusMessage ?? %"Searching…")
            }

            Section {
                Text("For AirPlay-compatible devices, use system Screen Mirroring")
            }
        } label: {
            Image(systemName: selectedRendererID == nil ? "airplay.video" : "airplay.video.circle.fill")
        }
        .menuOrder(.fixed)
        .labelStyle(.iconOnly)
        .imageScale(.medium)
        .accessibilityLabel("VLC Renderer Output")
        .task {
            CastTrustResponder.shared.start()
            await startDiscovery()
        }
        .onDisappear {
            stopDiscovery()
            CastTrustResponder.shared.stop()
        }
    }

    @MainActor
    private func startDiscovery() async {
        stopDiscovery()

        services = RendererDiscoverer.availableServices()
        guard !services.isEmpty else {
            statusMessage = %"player.renderer.noDiscoverers"
            return
        }

        statusMessage = %"Searching…"
        var startedDiscoverers: [RendererDiscoverer] = []
        var startedServiceNames: [String] = []

        for service in services {
            guard let discoverer = try? RendererDiscoverer(name: service.name) else { continue }

            do {
                try discoverer.start()
                startedDiscoverers.append(discoverer)
                startedServiceNames.append(service.longName)
                observe(discoverer)
            } catch {
                continue
            }
        }

        discoverers = startedDiscoverers
        if startedDiscoverers.isEmpty {
            statusMessage = %"player.renderer.discoveryFailed"
        } else {
            statusMessage = %"Searching…" //"Searching via \(startedServiceNames.joined(separator: ", "))"
        }
    }

    @MainActor
    private func observe(_ discoverer: RendererDiscoverer) {
        let task = Task { @MainActor in
            for await event in discoverer.events {
                guard !Task.isCancelled else { return }

                switch event {
                case .itemAdded(let renderer):
                    if !renderers.contains(renderer) {
                        renderers.append(renderer)
                    }
                case .itemDeleted(let renderer):
                    renderers.removeAll { $0 == renderer }
                    if selectedRendererID == renderer.id {
                        selectedRendererID = nil
                    }
                }
            }
        }
        observationTasks.append(task)
    }

    @MainActor
    private func stopDiscovery() {
        observationTasks.forEach { $0.cancel() }
        observationTasks = []
        discoverers.forEach { $0.stop() }
        discoverers = []
        renderers = []
    }

    @MainActor
    private func recast(to renderer: RendererItem?) {
        guard !isRecasting else { return }
        isRecasting = true
        statusMessage = renderer.map { String(format: %"player.renderer.connecting", $0.name) }
            ?? %"player.renderer.returningToDevice"

        Task { @MainActor in
            defer { isRecasting = false }

            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await player.recast(to: renderer) }
                    group.addTask {
                        try await Task.sleep(for: .seconds(8))
                        throw RendererRouteError.connectionTimedOut
                    }

                    try await group.next()
                    group.cancelAll()
                }

                selectedRendererID = renderer?.id
                statusMessage = renderer.map { String(format: %"player.renderer.connected", $0.name) }
                    ?? %"player.renderer.playingOnDevice"
            } catch {
                statusMessage = %"player.renderer.playbackFailed"
                selectedRendererID = nil
                try? await player.recast(to: nil)
            }
        }
    }
}

private enum RendererRouteError: Error {
    case connectionTimedOut
}

private extension RendererItem {
    var subtitle: String {
        let capabilities = [canVideo ? %"Video" : nil, canAudio ? %"Audio" : nil]
            .compactMap { $0 }
            .joined(separator: ", ")
        return capabilities.isEmpty ? type : "\(type) · \(capabilities)"
    }
}
