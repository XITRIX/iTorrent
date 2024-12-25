//
//  TrackersListService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 16/09/2024.
//

import Foundation
import LibTorrent
import MvvmFoundation
import Combine

extension TrackersListService.ListState {
    enum Status: Codable {
        case updated
        case error
    }

    enum Source: Identifiable, Codable, Hashable {
        var id: Self { self }

        case remote(URL)
        case local(UUID)
    }
}

extension TrackersListService {
    struct ListState: Identifiable, Codable {
        var id: Source { source }

        var source: Source
        var title: String
        var status: Status
        var trackers: [String]
    }
}

class TrackersListService: @unchecked Sendable {
    let trackerSources: CurrentValueSubject<[ListState.Source: ListState], Never>

    init() {
        trackerSources = CurrentValueSubject<[ListState.Source: ListState], Never>((try? Self.load()) ?? [:])

        trackerSources.sink { urls in
            try? Self.safe(urls)
        }.store(in: disposeBag)

        Task { await Self.refresh(trackerSources.value) }
    }

    private let disposeBag = DisposeBag()
    private static let key = "TrackersListServiceDataKey"
}

extension TrackersListService {
    func addTrackersSource(_ url: URL, title: String) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let trackers = String(data: data, encoding: .utf8)?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []
        let listState = ListState(source: .remote(url), title: title, status: .updated, trackers: trackers)
        trackerSources.value[listState.source] = listState
    }

    func createLocalSource(title: String) {
        let listState: TrackersListService.ListState = .init(source: .local(UUID()), title: title, status: .updated, trackers: [])
        trackerSources.value[listState.source] = listState
    }

    func addAllTrackers(to torrent: TorrentHandle) {
        trackerSources.value.values.forEach { state in
            state.trackers.forEach { urlString in
                guard let url = URL(string: urlString) else { return }
                torrent.addTracker(url.absoluteString)
            }
        }
    }
}

private extension TrackersListService {
    static func refresh(_ oldValues: [ListState.Source: ListState]) async -> [ListState.Source: ListState] {
        await withTaskGroup(of: ListState.self, returning: [ListState.Source: ListState].self) { taskGroup in
            oldValues.values.forEach { value in
                guard case let .remote(url) = value.source else { return }
                taskGroup.addTask {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        let trackers = String(data: data, encoding: .utf8)?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []
                        return ListState(source: value.source, title: value.title, status: .updated, trackers: trackers)
                    } catch {
                        return .init(source: value.source, title: value.title, status: .error, trackers: value.trackers)
                    }
                }
            }

            return await taskGroup.reduce(into: [ListState.Source: ListState]()) { partialResult, state in
                partialResult[state.source] = state
            }
        }
    }
}

private extension TrackersListService {
    static func load() throws -> [ListState.Source: ListState] {
        guard let data = UserDefaults.standard.data(forKey: key)
        else { return [:] }
        return try JSONDecoder().decode([ListState.Source: ListState].self, from: data)
    }

    static func safe(_ urls: [ListState.Source: ListState]) throws {
        let data = try JSONEncoder().encode(urls)
        UserDefaults.standard.set(data, forKey: key)
    }
}
