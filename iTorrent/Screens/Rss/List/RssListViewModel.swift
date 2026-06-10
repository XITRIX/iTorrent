//
//  RssListViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import Foundation
import MvvmFoundation

class RssListViewModel: BaseCollectionViewModel, @unchecked Sendable {
    required init() {
        super.init()
        setup()
    }

    private var updatesTask: Task<Void, Never>?
    private var currentFeeds: [RssFeedSnapshot] = []
    @Injected private var rssProvider: RssFeedProvider
}

extension RssListViewModel {
    var isEmpty: AnyPublisher<Bool, Never> {
        $sections.map { $0.isEmpty || $0.allSatisfy { $0.items.isEmpty } }
            .eraseToAnyPublisher()
    }

    var isRemoveAvailable: AnyPublisher<Bool, Never> {
        $selectedIndexPaths.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    func addFeed() {
        textInput(title: %"rsslist.add.title", placeholder: "https://", type: .URL, accept: %"common.add") { [unowned self] result in
            guard let result else { return }
            Task { [rssProvider] in
                _ = try? await rssProvider.addFeed(result)
            }
        }
    }

    func removeSelected() {
        let ids = selectedIndexPaths.compactMap {
            (sections[$0.section].items[$0.item] as? RssFeedCellViewModel)?.model.id
        }

        alert(title: %"rsslist.remove.title", message: %"rsslist.remove.message", actions: [
            .init(title: %"common.cancel", style: .cancel, isPrimary: true),
            .init(title: %"common.delete", style: .destructive, action: { [rssProvider] in
                Task { await rssProvider.removeFeeds(ids: ids) }
            })
        ])
    }

    func reorderItems(_ viewModels: [MvvmViewModel]) {
        let ids = viewModels.compactMap { ($0 as? RssFeedCellViewModel)?.model.id }
        Task { [rssProvider] in
            await rssProvider.reorderFeeds(ids: ids)
        }
    }

    func importChannels(from fileUrl: URL) async {
        guard let data = try? Data(contentsOf: fileUrl),
              let text = String(data: data, encoding: .utf8)
        else { return }

        for url in text.components(separatedBy: "\n") {
            guard URL(string: url) != nil else { continue }
            _ = try? await rssProvider.addFeed(url)
        }
    }

    func exportChannels(_ indexes: [IndexPath]) -> URL {
        let filePath = FileManager.default.temporaryDirectory.appending(path: "rssExport.txt")
        let urls = currentFeeds.enumerated()
            .filter { indexes.isEmpty || indexes.contains(IndexPath(item: $0.offset, section: 0)) }
            .map { $0.element.xmlLink }
        let text = urls.map(\.absoluteString).joined(separator: "\n")
        let data = text.data(using: .utf8)

        try? FileManager.default.removeItem(at: filePath)
        FileManager.default.createFile(atPath: filePath.path(percentEncoded: false), contents: data)

        return filePath
    }
}

private extension RssListViewModel {
    func setup() {
        Task { [rssProvider] in try? await rssProvider.fetchUpdates() }

        updatesTask = Task { [weak self, rssProvider] in
            for await models in await rssProvider.updates() {
                await self?.reload(with: models)
            }
        }

        refreshTask = { [weak self] in
            do { try await self?.rssProvider.fetchUpdates() }
            catch {}
        }
    }

    @MainActor
    func reload(with models: [RssFeedSnapshot]) {
        currentFeeds = models
        sections = [.init(id: "rss", items: models.map { model in
            RssFeedCellViewModel(with: .init(rssModel: model, selectAction: { [unowned self] in
                navigate(to: RssChannelViewModel.self, with: model, by: .show)
            }))
        })]
    }
}
