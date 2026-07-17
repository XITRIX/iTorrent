//
//  RendererRouteMenuView.swift
//  iTorrent
//

import SwiftUI
import SwiftVLC

@MainActor
final class RendererRouteController: ObservableObject {
    @Published private(set) var renderers: [RendererItem] = []
    @Published private(set) var selectedRenderer: RendererItem?
    @Published private(set) var isRecasting = false
    @Published private(set) var statusMessage: String?

    private var discoverers: [RendererDiscoverer] = []
    private var observationTasks: [Task<Void, Never>] = []
    private var recastTask: Task<Void, Never>?
    private var isStarted = false

    var selectedRendererID: RendererItem.ID? {
        selectedRenderer?.id
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        CastTrustResponder.shared.start()
        startDiscovery()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        recastTask?.cancel()
        recastTask = nil
        stopDiscovery()
        CastTrustResponder.shared.stop()
        selectedRenderer = nil
        isRecasting = false
        statusMessage = nil
    }

    func recast(to renderer: RendererItem?, on player: Player) {
        recast(to: renderer, on: player, isRecoveringFromFailure: false)
    }

    func handlePlaybackFailure(on player: Player) {
        guard selectedRenderer != nil, !isRecasting else { return }
        recast(to: nil, on: player, isRecoveringFromFailure: true)
    }

    private func startDiscovery() {
        stopDiscovery()

        let services = RendererDiscoverer.availableServices()
        guard !services.isEmpty else {
            statusMessage = %"player.renderer.noDiscoverers"
            return
        }

        statusMessage = %"Searching…"
        var startedDiscoverers: [RendererDiscoverer] = []

        for service in services {
            guard let discoverer = try? RendererDiscoverer(name: service.name) else { continue }

            do {
                try discoverer.start()
                startedDiscoverers.append(discoverer)
                observe(discoverer)
            } catch {
                continue
            }
        }

        discoverers = startedDiscoverers
        if startedDiscoverers.isEmpty {
            statusMessage = %"player.renderer.discoveryFailed"
        }
    }

    private func observe(_ discoverer: RendererDiscoverer) {
        let task = Task { @MainActor [weak self] in
            for await event in discoverer.events {
                guard let self, !Task.isCancelled else { return }

                switch event {
                case .itemAdded(let renderer):
                    if !renderers.contains(renderer) {
                        renderers.append(renderer)
                    }
                case .itemDeleted(let renderer):
                    // Discovery availability is independent from the active
                    // playback route. Keep the selected renderer until VLC
                    // confirms that its playback session has failed.
                    renderers.removeAll { $0 == renderer }
                }
            }
        }
        observationTasks.append(task)
    }

    private func stopDiscovery() {
        observationTasks.forEach { $0.cancel() }
        observationTasks = []
        discoverers.forEach { $0.stop() }
        discoverers = []
        renderers = []
    }

    private func recast(
        to renderer: RendererItem?,
        on player: Player,
        isRecoveringFromFailure: Bool
    ) {
        guard !isRecasting else { return }
        let previousRenderer = selectedRenderer
        isRecasting = true
        statusMessage = isRecoveringFromFailure
            ? %"player.renderer.playbackFailed"
            : renderer.map { String(format: %"player.renderer.connecting", $0.name) }
                ?? %"player.renderer.returningToDevice"

        recastTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                isRecasting = false
                recastTask = nil
            }

            do {
                try await performRecast(to: renderer, on: player)
                selectedRenderer = renderer
                statusMessage = nil // renderer.map { String(format: %"player.renderer.connected", $0.name) } ?? %"player.renderer.playingOnDevice"
            } catch is CancellationError {
                return
            } catch {
                statusMessage = %"player.renderer.playbackFailed"

                // A failed renderer switch can leave the replacement native
                // player bound to that renderer. Always make a best-effort
                // local recast before allowing playback controls to continue.
                guard renderer != nil else {
                    selectedRenderer = previousRenderer
                    return
                }

                do {
                    try await performRecast(to: nil, on: player)
                    selectedRenderer = nil
                    statusMessage = nil // %"player.renderer.playingOnDevice"
                } catch {
                    selectedRenderer = previousRenderer
                }
            }
        }
    }

    private func performRecast(to renderer: RendererItem?, on player: Player) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await player.recast(to: renderer)
                guard await player.state != .error else {
                    throw RendererRouteError.playbackFailed
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(8))
                throw RendererRouteError.connectionTimedOut
            }

            _ = try await group.next()
            group.cancelAll()
        }
    }
}

struct RendererRouteMenuView: View {
    let player: Player
    @ObservedObject var routeController: RendererRouteController

    @EnvironmentObject private var air: Air

    var body: some View {
        Menu {
            Section("Play on") {
                Button {
                    routeController.recast(to: nil, on: player)
                } label: {
                    Label(
                        air.connected ? "AirPlay" : "This Device",
                        systemImage: routeController.selectedRendererID == nil ? "checkmark" : "iphone"
                    )
                }
                .disabled(routeController.isRecasting)

//            if !services.isEmpty {
//                Section("Discovery") {
//                    ForEach(services, id: \.name) { service in
//                        Label(service.longName, systemImage: "network")
//                    }
//                }
//            }

                ForEach(routeController.renderers) { renderer in
                    Button {
                        routeController.recast(to: renderer, on: player)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(renderer.name)
                                Text(renderer.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: routeController.selectedRendererID == renderer.id ? "checkmark" : "tv")
                        }
                    }
                    .disabled(routeController.isRecasting || !renderer.canVideo)
                }
                if let status = routeController.statusMessage {
                    Text(status)
                }
            }

            if !air.connected {
                Section {
                    Text("For AirPlay-compatible devices, use system Screen Mirroring")
                }
            }
        } label: {
            Image(systemName: routeController.selectedRendererID == nil ? "airplay.video" : "airplay.video.circle.fill")
        }
        .menuOrder(.fixed)
        .labelStyle(.iconOnly)
        .imageScale(.medium)
        .accessibilityLabel("VLC Renderer Output")
    }
}

private enum RendererRouteError: Error {
    case connectionTimedOut
    case playbackFailed
}

private extension RendererItem {
    var subtitle: String {
        let capabilities = [canVideo ? %"Video" : nil, canAudio ? %"Audio" : nil]
            .compactMap { $0 }
            .joined(separator: ", ")
        return capabilities.isEmpty ? type : "\(type) · \(capabilities)"
    }
}
