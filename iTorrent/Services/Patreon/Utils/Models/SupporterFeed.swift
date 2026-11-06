import Foundation

/// The public feed contains display names only, never Patreon credentials or IDs.
struct SupporterFeed: Decodable {
    let version: Int
    let names: [String]

    enum ValidationError: Swift.Error {
        case invalidResponse
        case unsupportedVersion
        case invalidName
    }

    static func decode(_ data: Data) throws -> [String] {
        let feed = try JSONDecoder().decode(Self.self, from: data)
        guard feed.version == 1 else { throw ValidationError.unsupportedVersion }
        guard feed.names.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw ValidationError.invalidName }
        return feed.names
    }
}

struct SupporterFeedClient: Sendable {
    static let feedURL = URL(string: "https://raw.githubusercontent.com/XITRIX/iTorrent/patreon-data/supporters.json")!

    var session: URLSession = .shared
    var url: URL = Self.feedURL

    func fetchNames() async throws -> [String] {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode)
        else { throw SupporterFeed.ValidationError.invalidResponse }
        return try SupporterFeed.decode(data)
    }
}
