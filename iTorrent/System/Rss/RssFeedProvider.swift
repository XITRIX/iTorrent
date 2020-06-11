//
//  RssFeedProvider.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import SwiftyXMLParser

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

    private let disposalBag = DisposalBag()
    public static let shared = RssFeedProvider()

    var rssModels = Box<[RssModel]>([])
    var isRssUpdates = Box<Bool>(false)

    init() {
        loadFromDisk()
        fetchUpdates()
        rssModels.bind { models in
            self.isRssUpdates.variable = models.contains(where: { !$0.muteNotifications && $0.updatesCount > 0 })
            self.saveToDisk()
        }.dispose(with: disposalBag)
    }

    func fetchUpdates(completion: (([RssModel: [RssItemModel]]) -> Void)? = nil) {
        var res = [RssModel: [RssItemModel]]()
        DispatchQueue.global(qos: .background).async {
            for feed in self.rssModels.variable {
                if let result = try? self.loadFeedAsync(feed.xmlLink) {
                    let updates = feed.update(result)
                    if updates.count > 0 {
                        res[feed] = updates
                    }
                }
            }

            self.rssModels.notifyUpdate()
            DispatchQueue.main.async {
                completion?(res)
            }
        }
    }

    func addFeed(_ url: String, completion: ((Result<RssModel, Swift.Error>) -> Void)? = nil) {
        guard let url = URL(string: url) else {
            completion?(.failure(RssError.wrongUrl))
            return
        }

        if rssModels.variable.contains(where: { $0.xmlLink == url }) {
            completion?(.failure(RssError.feedExists))
            return
        }

        loadFeed(url) { result in
            switch result {
            case .success(let model):
                self.rssModels.variable.insert(model, at: 0)
            case .failure:
                break
            }
            completion?(result)
        }
    }

    func removeFeeds(_ feedsUrl: [URL]) {
        rssModels.multiplyUpdate {
            rssModels.variable.removeAll(where: { feedsUrl.contains($0.link) })
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
        if let encoded = try? encoder.encode(rssModels.variable) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "RssFeed")
        }
    }

    func loadFromDisk() {
        let defaults = UserDefaults.standard
        if let rssFeed = defaults.object(forKey: "RssFeed") as? Data {
            let decoder = JSONDecoder()
            if let loadedRssFeed = try? decoder.decode([RssModel].self, from: rssFeed) {
                rssModels.variable = loadedRssFeed
            }
        }
    }
}
