//
//  PatreonService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/05/2024.
//

import Combine
import Foundation
import MvvmFoundation

struct PatreonToken: Codable {
    var accessToken: String
    var refreshToken: String
}

class PatreonService: @unchecked Sendable {
    init() {
        Task {
            try await fetchCredentials()
            try await fetchAccount()
        }
    }

    private var authenticationSession: BaseSafariViewController?
    private let session = URLSession(configuration: .ephemeral)

    private static let redirectUri = "http://127.0.0.1:25565"
    private static let baseURL = URL(string: "https://www.patreon.com/")!
    private static let credentialsUrl: String = "https://firebasestorage.googleapis.com/v0/b/itorrent-fdb49.appspot.com/o/credentials.json?alt=media"

    @Injected private var preferences: PreferencesStorage
}

extension PatreonService {
    private var credentials: PatreonCredentials? {
        get async {
            if let credentials = preferences.patreonCredentials { return credentials }
            return try? await fetchCredentials()
        }
    }

    var isAuthenticated: Bool {
        preferences.patreonToken != nil
    }

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        preferences.$patreonToken
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    @discardableResult
    func authenticate(from context: NavigationProtocol) async throws -> PatreonAccount {
        guard let credentials = await credentials
        else { throw Error.noCredentials }

        var components = URLComponents(string: "/oauth2/authorize")!
        components.queryItems = [URLQueryItem(name: "response_type", value: "code"),
                                 URLQueryItem(name: "client_id", value: credentials.clientID),
                                 URLQueryItem(name: "redirect_uri", value: Self.redirectUri)]

        let requestURL = components.url(relativeTo: Self.baseURL)!

        authenticationSession = await BaseSafariViewController(url: requestURL)

        await MainActor.run {
            authenticationSession?.modalPresentationStyle = .pageSheet
            context.present(authenticationSession!, animated: true)
        }

        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Swift.Error>) in
            do {
                try PatreonWebServer.shared.run { [self] code in
                    Task {
                        await authenticationSession?.dismiss(animated: true)
                        guard let code else {
                            continuation.resume(with: .failure(Error.unknown))
                            return
                        }

                        continuation.resume(returning: code)
                    }
                }
            }
            catch {
                continuation.resume(throwing: error)
            }
        }

        let token = try await fetchAccessToken(oauthCode: code)
        print(token)

        await MainActor.run {
            preferences.patreonToken = token
        }
        return try await fetchAccount()
    }
}

extension PatreonService {
    @discardableResult
    func fetchCredentials() async throws -> PatreonCredentials {
        let request = URLRequest(url: URL(string: Self.credentialsUrl)!)
        let credentials: PatreonCredentials = try await send(request, authorizationType: .none)

        preferences.patreonCredentials = credentials
        return credentials
    }

    @discardableResult
    func fetchAccount() async throws -> PatreonAccount {
        var components = URLComponents(string: "/api/oauth2/v2/identity")!
        components.queryItems = [URLQueryItem(name: "include", value: "memberships"),
                                 URLQueryItem(name: "fields[user]", value: "first_name,full_name"),
                                 URLQueryItem(name: "fields[member]", value: "full_name,patron_status")]

        let requestURL = components.url(relativeTo: Self.baseURL)!
        let request = URLRequest(url: requestURL)
        print(requestURL.absoluteString)
        do {
            let response: AccountResponse = try await send(request, authorizationType: .user)

            let account = PatreonAccount(response: response)
            await MainActor.run {
                preferences.patreonAccount = account
            }
            return account
        }
        catch Error.notAuthenticated {
            try signOut()
            throw Error.notAuthenticated
        }
        catch {
            throw error
        }
    }

    func fetchPatrons() async throws -> [Patron] {
        guard let credentials = await credentials
        else { throw Error.noCredentials }

        var components = URLComponents(string: "/api/oauth2/v2/campaigns/\(credentials.campaignID)/members")!
//        components.queryItems = [URLQueryItem(name: "include", value: "currently_entitled_tiers,currently_entitled_tiers.benefits,user"),
        components.queryItems = [URLQueryItem(name: "include", value: "currently_entitled_tiers,currently_entitled_tiers.benefits"),
                                 URLQueryItem(name: "fields[tier]", value: "title"),
                                 URLQueryItem(name: "fields[member]", value: "full_name,patron_status"),
                                 URLQueryItem(name: "page[size]", value: "1000")]

        let requestURL = components.url(relativeTo: Self.baseURL)!

        struct Response: Decodable {
            var data: [PatronResponse]
            var included: [AnyResponse]
            var links: [String: URL]?
        }

        var allPatrons = [Patron]()

        @Sendable func fetchPatrons(url: URL, allPatrons: inout [Patron]) async throws {
            let request = URLRequest(url: url)

            let response: Response = try await send(request, authorizationType: .creator)
            let tiers = response.included.compactMap { response -> Tier? in
                switch response {
                case .tier(let tierResponse): return Tier(response: tierResponse)
                case .benefit: return nil
                }
            }

            let tiersByIdentifier = Dictionary(tiers.map { ($0.identifier, $0) }, uniquingKeysWith: { a, _ in a })

            let patrons = response.data.map { response -> Patron in
                let patron = Patron(response: response)

                for tierID in response.relationships?.currently_entitled_tiers.data ?? [] {
                    guard let tier = tiersByIdentifier[tierID.id]
                    else { continue }
                    patron.benefits.formUnion(tier.benefits)
                }

                return patron
            }
            // .filter { $0.benefits.contains(where: { $0.type == .credits }) }

            allPatrons.append(contentsOf: patrons)

            if let nextURL = response.links?["next"] {
                try await fetchPatrons(url: nextURL, allPatrons: &allPatrons)
            }
        }

        try await fetchPatrons(url: requestURL, allPatrons: &allPatrons)
        return allPatrons
    }

    func fetchPledgeHistory() async throws {
        guard let account = preferences.patreonAccount,
              let id = account.id
        else { throw Error.notAuthenticated }

        var components = URLComponents(string: "/api/oauth2/v2/members/\(id)")!
        components.queryItems = [URLQueryItem(name: "include", value: "pledge_history")]

        let requestURL = components.url(relativeTo: Self.baseURL)!
        let request = URLRequest(url: requestURL)
        print(requestURL.absoluteString)
        do {
            let response: MemberResponse = try await send(request, authorizationType: .user)

            guard let pledgeHistory = response.included else {
                throw Error.unknown
            }

            preferences.patreonAccount?.applyPledgeHistory(pledgeHistory: pledgeHistory)
            return
        }
        catch Error.notAuthenticated {
            try signOut()
            throw Error.notAuthenticated
        }
        catch {
            throw error
        }
    }

    func signOut() throws {
        if preferences.patreonAccount?.fixedAccount ?? false {
            throw Error.notAuthenticated
        }

        preferences.patreonAccount = nil
        preferences.patreonToken = nil
    }
}

private extension PatreonService {
    func fetchAccessToken(oauthCode: String) async throws -> PatreonToken {
        guard let credentials = await credentials
        else { throw Error.noCredentials }

        let encodedOauthCode = (oauthCode as NSString).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!

        let body = "code=\(encodedOauthCode)&grant_type=authorization_code&client_id=\(credentials.clientID)&client_secret=\(credentials.clientSecret)&redirect_uri=\(Self.redirectUri)"

        let requestURL = URL(string: "/api/oauth2/token", relativeTo: Self.baseURL)!

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        struct Response: Decodable {
            var access_token: String
            var refresh_token: String
        }

        let response: Response = try await send(request, authorizationType: .none)
        return .init(accessToken: response.access_token, refreshToken: response.refresh_token)
    }

    func refreshAccessToken() async throws {
        guard let credentials = await credentials
        else { throw Error.noCredentials }

        guard let refreshToken = preferences.patreonToken?.refreshToken else { return }

        var components = URLComponents(string: "/api/oauth2/token")!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token"),
                                 URLQueryItem(name: "refresh_token", value: refreshToken),
                                 URLQueryItem(name: "client_id", value: credentials.clientID),
                                 URLQueryItem(name: "client_secret", value: credentials.clientSecret)]

        let requestURL = components.url(relativeTo: Self.baseURL)!

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"

        struct Response: Decodable {
            var access_token: String
            var refresh_token: String
        }

        let response: Response = try await send(request, authorizationType: .none)
        preferences.patreonToken = .init(accessToken: response.access_token, refreshToken: response.refresh_token)
    }

    func send<ResponseType: Decodable>(_ request: URLRequest, authorizationType: AuthorizationType) async throws -> ResponseType {
        var request = request

        switch authorizationType {
        case .none: break
        case .creator:
            guard let creatorAccessToken = preferences.patreonCredentials?.patreonCreatorAccessToken else { throw Error.invalidAccessToken }
            request.setValue("Bearer " + creatorAccessToken, forHTTPHeaderField: "Authorization")
        case .user:
            guard let accessToken = preferences.patreonToken?.accessToken else { throw Error.notAuthenticated }
            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }

        let (data, dataResponse) = try await session.data(for: request)

        if let response = dataResponse as? HTTPURLResponse, response.statusCode == 401 {
            switch authorizationType {
            case .creator: throw Error.invalidAccessToken
            case .none: throw Error.notAuthenticated
            case .user:
                try await refreshAccessToken()
                return try await send(request, authorizationType: authorizationType)
            }
        }

        let response = try JSONDecoder().decode(ResponseType.self, from: data)
        return response
    }
}
