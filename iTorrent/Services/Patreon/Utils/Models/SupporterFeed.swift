import Foundation

struct Supporter: Codable, Equatable, Sendable {
    let name: String
    let avatarURL: URL?
    /// UTC calendar date at the beginning of the current pledge chain.
    let since: String?

    enum CodingKeys: String, CodingKey {
        case name, since
        case avatarURL = "avatar_url"
    }

    var supportStartDate: Date? {
        guard let since, since.count == 10 else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: since), formatter.string(from: date) == since else { return nil }
        return date
    }

    func supportDuration(relativeTo now: Date = Date()) -> String? {
        guard let start = supportStartDate, start <= now else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day], from: start, to: now)
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = (components.year ?? 0) > 0 || (components.month ?? 0) > 0 ? [.year, .month] : [.day]
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: components)
    }

    static func longestSupportingFirst(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.since != rhs.since {
            return (lhs.since ?? "9999-12-31") < (rhs.since ?? "9999-12-31")
        }
        let order = lhs.name.localizedStandardCompare(rhs.name)
        if order != .orderedSame { return order == .orderedAscending }
        if lhs.name != rhs.name { return lhs.name < rhs.name }
        return (lhs.avatarURL?.absoluteString ?? "") < (rhs.avatarURL?.absoluteString ?? "")
    }
}

/// Only display names, public avatar URLs and pledge-start dates are published.
struct SupporterFeed: Decodable {
    let version: Int
    let supporters: [Supporter]

    enum ValidationError: Swift.Error {
        case invalidResponse
        case unsupportedVersion
        case invalidSupporter
    }

    static func decode(_ data: Data) throws -> [Supporter] {
        let feed = try JSONDecoder().decode(Self.self, from: data)
        guard feed.version == 1 else { throw ValidationError.unsupportedVersion }
        for supporter in feed.supporters {
            guard !supporter.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  supporter.since == nil || supporter.supportStartDate != nil
            else { throw ValidationError.invalidSupporter }
            if let url = supporter.avatarURL {
                guard url.scheme == "https", let host = url.host, !host.isEmpty,
                      url.user == nil, url.password == nil, url.fragment == nil
                else { throw ValidationError.invalidSupporter }
            }
        }
        return feed.supporters.sorted(by: Supporter.longestSupportingFirst)
    }
}

struct SupporterFeedClient: Sendable {
    static let feedURL = URL(string: "https://raw.githubusercontent.com/XITRIX/iTorrent/patreon-data/supporters.json")!

    var session: URLSession = .shared
    var url: URL = Self.feedURL

    func fetchSupporters() async throws -> [Supporter] {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode)
        else { throw SupporterFeed.ValidationError.invalidResponse }
        return try SupporterFeed.decode(data)
    }
}
