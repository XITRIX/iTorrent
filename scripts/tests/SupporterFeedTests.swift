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
            (#"{"version":1,"names":["Alice","Élodie 🌟","李明"]}"#, 200, ["Alice", "Élodie 🌟", "李明"]),
            (#"{"version":1,"names":[]}"#, 200, []),
            (#"{"version":2,"names":[]}"#, 200, nil),
            (#"{"version":1,"names":["  "]}"#, 200, nil),
            (#"{"version":1,"names":[null]}"#, 200, nil),
            (#"{"version":1,"names":[42]}"#, 200, nil),
            (#"{"version":true,"names":[]}"#, 200, nil),
            (#"{"names":[]}"#, 200, nil),
            ("not json", 200, nil),
            (#"{"version":1,"names":["Must not display"]}"#, 404, nil),
            (#"{"version":1,"names":[]}"#, 500, nil)
        ]
        for (payload, status, expected) in cases {
            FeedURLProtocol.payload = Data(payload.utf8)
            FeedURLProtocol.status = status
            do {
                let names = try await client.fetchNames()
                precondition(expected == names, "Unexpected successful response: \(status), \(payload)")
            } catch {
                precondition(expected == nil, "Valid feed was rejected: \(error)")
            }
        }
        FeedURLProtocol.failure = URLError(.notConnectedToInternet)
        do {
            _ = try await client.fetchNames()
            preconditionFailure("Offline request should fail")
        } catch { }
        print("Supporter feed: 12 HTTP, schema, Unicode, empty, and offline scenarios passed.")
    }
}
