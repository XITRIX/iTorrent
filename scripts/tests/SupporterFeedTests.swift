// Standalone Foundation tests: no app signing, UIKit, or third-party packages.
import Foundation

private final class FeedURLProtocol: URLProtocol {
    static var status = 200
    static var payload = Data()
    static var failure: Swift.Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
        if let failure = Self.failure {
            client?.urlProtocol(self, didFailWithError: failure)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.payload)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@main
struct SupporterFeedTests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FeedURLProtocol.self]
        let client = SupporterFeedClient(session: URLSession(configuration: configuration), url: URL(string: "https://example.invalid/supporters.json")!)
        let cases: [(String, Int, [String]?)] = [
            (#"{"version":1,"supporters":[{"name":"Alice","avatar_url":"https://example.com/a.png","since":"2020-01-01"},{"name":"Élodie 🌟","avatar_url":null,"since":null},{"name":"李明","since":"2022-01-01"}]}"#, 200, ["Alice", "李明", "Élodie 🌟"]),
            (#"{"version":1,"supporters":[]}"#, 200, []),
            (#"{"version":2,"supporters":[]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":"  "}]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":null}]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":42}]}"#, 200, nil),
            (#"{"version":true,"supporters":[]}"#, 200, nil),
            (#"{"supporters":[]}"#, 200, nil),
            (#"{"version":1,"names":["Alice"]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":"Alice","since":"2023-02-30"}]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":"Alice","since":"2023-1-2"}]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":"Alice","avatar_url":"http://example.com/a.png"}]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":"Alice","avatar_url":"https://user:password@example.com/a.png"}]}"#, 200, nil),
            (#"{"version":1,"supporters":[{"name":"Alice","avatar_url":"file:///tmp/a.png"}]}"#, 200, nil),
            ("not json", 200, nil),
            (#"{"version":1,"supporters":[{"name":"Must not display"}]}"#, 404, nil),
            (#"{"version":1,"supporters":[]}"#, 500, nil)
        ]
        for (payload, status, expected) in cases {
            FeedURLProtocol.payload = Data(payload.utf8)
            FeedURLProtocol.status = status
            do {
                let supporters = try await client.fetchSupporters()
                precondition(expected == supporters.map(\.name), "Unexpected successful response: \(status), \(payload)")
                let restored = try JSONDecoder().decode([Supporter].self, from: JSONEncoder().encode(supporters))
                precondition(restored == supporters, "Cached supporter metadata must round-trip")
            } catch {
                precondition(expected == nil, "Valid feed was rejected: \(error)")
            }
        }
        let supporter = Supporter(name: "Alice", avatarURL: nil, since: "2020-01-01")
        let now = ISO8601DateFormatter().date(from: "2022-04-01T00:00:00Z")!
        precondition(supporter.supportDuration(relativeTo: now) != nil)
        precondition(supporter.supportDuration(relativeTo: now) == supporter.supportDuration(relativeTo: now.addingTimeInterval(86400)))
        precondition(Supporter(name: "Future", avatarURL: nil, since: "2025-01-01").supportDuration(relativeTo: now) == nil)
        precondition(Supporter(name: "Unknown", avatarURL: nil, since: nil).supportDuration(relativeTo: now) == nil)
        let metadata = try SupporterFeed.decode(Data(#"{"version":1,"supporters":[{"name":"Alice","avatar_url":"https://example.com/a.png","since":"2020-01-01"}]}"#.utf8))[0]
        precondition(metadata.avatarURL == URL(string: "https://example.com/a.png"))
        precondition(metadata.supportStartDate == ISO8601DateFormatter().date(from: "2020-01-01T00:00:00Z"))
        FeedURLProtocol.failure = URLError(.notConnectedToInternet)
        do {
            _ = try await client.fetchSupporters()
            preconditionFailure("Offline request should fail")
        } catch { }
        print("Supporter feed: HTTP/schema, metadata, oldest-first sorting, duration, cache and offline scenarios passed.")
    }
}
