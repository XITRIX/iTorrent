//
//  RssFeedProvider.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond
import Foundation
import SwiftyXMLParser
import ReactiveKit

class RssFeedProvider {
    enum RssError: LocalizedError {
        case unknown
        case wrongUrl
        case feedExists

        var errorDescription: String? {
            switch self {
            case .unknown: return Localize.get("RssFeedProvider.Error.Unknown")
            case .wrongUrl: return Localize.get("RssFeedProvider.Error.NotValid")
            case .feedExists: return Localize.get("RssFeedProvider.Error.Exists")
            }
        }
    }

    private let disposalBag = DisposeBag()
    public static let shared = RssFeedProvider()

    var rssModels = MutableObservableArray<RssModel>([])
    var isRssUpdates = Observable<Bool>(false)

    init() {
        loadFromDisk()
        fetchUpdates()
        rssModels.observeNext { models in
            self.isRssUpdates.value = self.rssModels.collection.contains(where: { !$0.muteNotifications.value && $0.updatesCount > 0 })
            self.saveToDisk()
        }.dispose(in: disposalBag)
    }

    func fetchUpdates(completion: (([RssModel: [RssItemModel]]) -> Void)? = nil) {
        var res = [RssModel: [RssItemModel]]()
        DispatchQueue.global(qos: .background).async {
            for feed in self.rssModels.collection {
                if let result = try? self.loadFeedAsync(feed.xmlLink) {
                    let updates = feed.update(result)
                    if updates.count > 0 {
                        res[feed] = updates
                    }
                }
            }

            DispatchQueue.main.async {
                self.rssModels.notifyUpdate()
                completion?(res)
            }
        }
    }

    func addFeed(_ url: String, completion: ((Result<RssModel, Swift.Error>) -> Void)? = nil) {
        guard let url = URL(string: url) else {
            completion?(.failure(RssError.wrongUrl))
            return
        }

        if rssModels.collection.contains(where: { $0.xmlLink == url }) {
            completion?(.failure(RssError.feedExists))
            return
        }

        loadFeed(url) { result in
            switch result {
            case .success(let model):
                self.rssModels.insert(model, at: 0)
            case .failure:
                break
            }
            completion?(result)
        }
    }

    func removeFeeds(_ feedModels: [RssModel]) {
        for url in feedModels {
            if let index = rssModels.collection.firstIndex(of: url) {
                rssModels.remove(at: index)
            }
        }
    }

    func loadFeed(_ url: URL, completion: @escaping (Result<RssModel, Swift.Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let model = try RssModel(link: url)
                DispatchQueue.main.async {
                    completion(.success(model))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func loadFeedAsync(_ url: URL) throws -> RssModel {
        let semaphore = DispatchSemaphore(value: 0)
        var res: Result<RssModel, Error>!

        loadFeed(url) { result in
            res = result
            semaphore.signal()
        }

        semaphore.wait()
        return try res.get()
    }
}

extension RssFeedProvider {
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(rssModels.value.collection) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "RssFeed")
        }
    }

    func loadFromDisk() {
        let defaults = UserDefaults.standard
        if let rssFeed = defaults.object(forKey: "RssFeed") as? Data {
            let decoder = JSONDecoder()
            if let loadedRssFeed = try? decoder.decode([RssModel].self, from: rssFeed) {
                rssModels.replace(with: loadedRssFeed)
            }
        }
    }
}
