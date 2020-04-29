//
//  PatreonAPI.swift
//  AltStore
//
//  Created by Riley Testut on 8/20/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import SafariServices
import UIKit

let credentialsUrl: String = "https://firebasestorage.googleapis.com/v0/b/itorrent-7f67b.appspot.com/o/credentials.json?alt=media"

struct PatreonCredentials: Codable {
    struct Benefits: Codable {
        var fullVersion: [String]
    }
    
    var clientID: String
    var clientSecret: String
    var patreonCreatorAccessToken: String
    var campaignID: String
    var hideFSAds: Bool
    var benefits: Benefits
}

private let redirectUri = "http://127.0.0.1:55555"

extension PatreonAPI {
    func fetchCredentials(completion: ((Result<PatreonCredentials, Swift.Error>) -> Void)? = nil)
    {
        let request = URLRequest(url: URL(string: credentialsUrl)!)
        send(request, authorizationType: .none) { (result: Result<PatreonCredentials, Swift.Error>) in
            do {
                let credentials = try result.get()
                UserPreferences.patreonCredentials = credentials
                completion?(.success(credentials))
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    static func configure() {
        PatreonAPI.shared.fetchCredentials { result in
            do {
                _ = try result.get()
                PatreonAPI.shared.refreshPatreonAccount()
            } catch {}
        }
    }
}

extension PatreonAPI {
    enum Error: LocalizedError
    {
        case unknown
        case notAuthenticated
        case invalidAccessToken
        case noCredentials
        
        var errorDescription: String?
        {
            switch self
            {
            case .unknown: return NSLocalizedString("An unknown error occurred.", comment: "")
            case .notAuthenticated: return NSLocalizedString("No connected Patreon account.", comment: "")
            case .invalidAccessToken: return NSLocalizedString("Invalid access token.", comment: "")
            case .noCredentials: return NSLocalizedString("No credentials.", comment: "")
            }
        }
    }
    
    enum AuthorizationType
    {
        case none
        case user
        case creator
    }
    
    enum AnyResponse: Decodable
    {
        case tier(TierResponse)
        case benefit(BenefitResponse)
        
        enum CodingKeys: String, CodingKey
        {
            case type
        }
        
        init(from decoder: Decoder) throws
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let type = try container.decode(String.self, forKey: .type)
            switch type
            {
            case "tier":
                let tier = try TierResponse(from: decoder)
                self = .tier(tier)
                
            case "benefit":
                let benefit = try BenefitResponse(from: decoder)
                self = .benefit(benefit)
                
            default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unrecognized Patreon response type.")
            }
        }
    }
}

class PatreonAPI: NSObject
{
    static let shared = PatreonAPI()
    
    var isAuthenticated: Bool
    {
        return UserPreferences.patreonAccessToken != nil
    }
    
    private var authenticationSession: UIViewController?
    
    private let session = URLSession(configuration: .ephemeral)
    private let baseURL = URL(string: "https://www.patreon.com/")!
    
    private override init()
    {
        super.init()
    }
}

extension PatreonAPI
{
    func authenticate(completion: @escaping (Result<PatreonAccount, Swift.Error>) -> Void)
    {
        guard let credentials = UserPreferences.patreonCredentials else
        {
            completion(.failure(Error.noCredentials))
            return
        }
        
        var components = URLComponents(string: "/oauth2/authorize")!
        components.queryItems = [URLQueryItem(name: "response_type", value: "code"),
                                 URLQueryItem(name: "client_id", value: credentials.clientID),
                                 URLQueryItem(name: "redirect_uri", value: redirectUri)]
        
        let requestURL = components.url(relativeTo: self.baseURL)!
        
        self.authenticationSession = SFSafariViewController(url: requestURL)
        self.authenticationSession?.modalPresentationStyle = .pageSheet
        
        PatreonWebServer.shared.run { [weak self] code in
            self?.authenticationSession?.dismiss(animated: true)
            do
            {
                guard let code = code
                else { throw Error.unknown }
                
                self?.fetchAccessToken(oauthCode: code) { result in
                    switch result
                    {
                    case .failure(let error): completion(.failure(error))
                    case .success(let accessToken, let refreshToken):
                        print(accessToken)
                        UserPreferences.patreonAccessToken = accessToken
                        UserPreferences.patreonRefreshToken = refreshToken
                        
                        self?.fetchAccount(completion: completion)
                    }
                }
            }
            catch
            {
                completion(.failure(error))
            }
        }
        
        Utils.topViewController?.present(self.authenticationSession!, animated: true)
    }
    
    func fetchAccount(completion: ((Result<PatreonAccount, Swift.Error>) -> Void)? = nil)
    {
        var components = URLComponents(string: "/api/oauth2/v2/identity")!
        components.queryItems = [URLQueryItem(name: "include", value: "memberships"),
                                 URLQueryItem(name: "fields[user]", value: "first_name,full_name"),
                                 URLQueryItem(name: "fields[member]", value: "full_name,patron_status")]
        
        let requestURL = components.url(relativeTo: self.baseURL)!
        let request = URLRequest(url: requestURL)
        print(requestURL.absoluteString)
        self.send(request, authorizationType: .user) { (result: Result<AccountResponse, Swift.Error>) in
            switch result
            {
            case .failure(Error.notAuthenticated):
                self.signOut { _ in
                    completion?(.failure(Error.notAuthenticated))
                }
                
            case .failure(let error): completion?(.failure(error))
            case .success(let response):
                let account = PatreonAccount(response: response)
                UserPreferences.patreonAccount = account
                completion?(.success(account))
            }
        }
    }
    
    func fetchPatrons(completion: @escaping (Result<[Patron], Swift.Error>) -> Void)
    {
        guard let credentials = UserPreferences.patreonCredentials else
        {
            completion(.failure(Error.noCredentials))
            return
        }
        
        var components = URLComponents(string: "/api/oauth2/v2/campaigns/\(credentials.campaignID)/members")!
//        components.queryItems = [URLQueryItem(name: "include", value: "currently_entitled_tiers,currently_entitled_tiers.benefits,user"),
        components.queryItems = [URLQueryItem(name: "include", value: "currently_entitled_tiers,currently_entitled_tiers.benefits"),
                                 URLQueryItem(name: "fields[tier]", value: "title"),
                                 URLQueryItem(name: "fields[member]", value: "full_name,patron_status"),
                                 URLQueryItem(name: "page[size]", value: "1000")]
        
        let requestURL = components.url(relativeTo: self.baseURL)!
        
        struct Response: Decodable
        {
            var data: [PatronResponse]
            var included: [AnyResponse]
            var links: [String: URL]?
        }
        
        var allPatrons = [Patron]()
        
        func fetchPatrons(url: URL)
        {
            let request = URLRequest(url: url)
            
            self.send(request, authorizationType: .creator) { (result: Result<Response, Swift.Error>) in
                switch result
                {
                case .failure(let error): completion(.failure(error))
                case .success(let response):
                    let tiers = response.included.compactMap { (response) -> Tier? in
                        switch response
                        {
                        case .tier(let tierResponse): return Tier(response: tierResponse)
                        case .benefit: return nil
                        }
                    }
                    
                    let tiersByIdentifier = Dictionary(tiers.map { ($0.identifier, $0) }, uniquingKeysWith: { a, _ in a })
                    
                    let patrons = response.data.map { (response) -> Patron in
                        let patron = Patron(response: response)
                        
                        for tierID in response.relationships?.currently_entitled_tiers.data ?? []
                        {
                            guard let tier = tiersByIdentifier[tierID.id] else { continue }
                            patron.benefits.formUnion(tier.benefits)
                        }
                        
                        return patron
                    }
                    // .filter { $0.benefits.contains(where: { $0.type == .credits }) }
                    
                    allPatrons.append(contentsOf: patrons)
                    
                    if let nextURL = response.links?["next"]
                    {
                        fetchPatrons(url: nextURL)
                    }
                    else
                    {
                        completion(.success(allPatrons))
                    }
                }
            }
        }
        
        fetchPatrons(url: requestURL)
    }
    
    func fetchPledgeHistory(completion: ((Result<Void, Swift.Error>) -> Void)? = nil)
    {
        guard let acсount = UserPreferences.patreonAccount,
            let id = acсount.id else
        {
            completion?(.failure(Error.notAuthenticated))
            return
        }
        
        var components = URLComponents(string: "/api/oauth2/v2/members/\(id)")!
        components.queryItems = [URLQueryItem(name: "include", value: "pledge_history")]
        
        let requestURL = components.url(relativeTo: self.baseURL)!
        let request = URLRequest(url: requestURL)
        print(requestURL.absoluteString)
        self.send(request, authorizationType: .user) { (result: Result<MemberResponse, Swift.Error>) in
            switch result
            {
            case .failure(Error.notAuthenticated):
                self.signOut { _ in
                    completion?(.failure(Error.notAuthenticated))
                }
                
            case .failure(let error): completion?(.failure(error))
            case .success(let response):
                guard let pledgeHistory = response.included else
                {
                    completion?(.failure(Error.unknown))
                    return
                }
                
                UserPreferences.patreonAccount?.applyPledgeHistory(pledgeHistory: pledgeHistory)
                completion?(.success(()))
            }
        }
    }
    
    func signOut(completion: @escaping (Result<Void, Swift.Error>) -> Void)
    {
        UserPreferences.patreonAccount = nil
        UserPreferences.patreonAccessToken = nil
        UserPreferences.patreonRefreshToken = nil
        
        completion(.success(()))
    }
}

extension PatreonAPI
{
    func refreshPatreonAccount()
    {
        guard PatreonAPI.shared.isAuthenticated else { return }
        
        PatreonAPI.shared.fetchAccount { (result: Result<PatreonAccount, Swift.Error>) in
            do
            {
                let account = try result.get()
                UserPreferences.patreonAccount = account
            }
            catch
            {
                print("Failed to fetch Patreon account.", error)
            }
        }
    }
}

private extension PatreonAPI
{
    func fetchAccessToken(oauthCode: String, completion: @escaping (Result<(String, String), Swift.Error>) -> Void)
    {
        guard let credentials = UserPreferences.patreonCredentials else
        {
            completion(.failure(Error.noCredentials))
            return
        }
        
        let encodedOauthCode = (oauthCode as NSString).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        let body = "code=\(encodedOauthCode)&grant_type=authorization_code&client_id=\(credentials.clientID)&client_secret=\(credentials.clientSecret)&redirect_uri=\(redirectUri)"
        
        let requestURL = URL(string: "/api/oauth2/token", relativeTo: self.baseURL)!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        struct Response: Decodable
        {
            var access_token: String
            var refresh_token: String
        }
        
        self.send(request, authorizationType: .none) { (result: Result<Response, Swift.Error>) in
            switch result
            {
            case .failure(let error): completion(.failure(error))
            case .success(let response): completion(.success((response.access_token, response.refresh_token)))
            }
        }
    }
    
    func refreshAccessToken(completion: @escaping (Result<Void, Swift.Error>) -> Void)
    {
        guard let credentials = UserPreferences.patreonCredentials else
        {
            completion(.failure(Error.noCredentials))
            return
        }
        
        guard let refreshToken = UserPreferences.patreonRefreshToken else { return }
        
        var components = URLComponents(string: "/api/oauth2/token")!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token"),
                                 URLQueryItem(name: "refresh_token", value: refreshToken),
                                 URLQueryItem(name: "client_id", value: credentials.clientID),
                                 URLQueryItem(name: "client_secret", value: credentials.clientSecret)]
        
        let requestURL = components.url(relativeTo: self.baseURL)!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        
        struct Response: Decodable
        {
            var access_token: String
            var refresh_token: String
        }
        
        self.send(request, authorizationType: .none) { (result: Result<Response, Swift.Error>) in
            switch result
            {
            case .failure(let error): completion(.failure(error))
            case .success(let response):
                UserPreferences.patreonAccessToken = response.access_token
                UserPreferences.patreonRefreshToken = response.refresh_token
                
                completion(.success(()))
            }
        }
    }
    
    func send<ResponseType: Decodable>(_ request: URLRequest, authorizationType: AuthorizationType, completion: @escaping (Result<ResponseType, Swift.Error>) -> Void)
    {
        var request = request
        
        switch authorizationType
        {
        case .none: break
        case .creator:
            guard let creatorAccessToken = UserPreferences.patreonCredentials?.patreonCreatorAccessToken else { return completion(.failure(Error.invalidAccessToken)) }
            request.setValue("Bearer " + creatorAccessToken, forHTTPHeaderField: "Authorization")
        case .user:
            guard let accessToken = UserPreferences.patreonAccessToken else { return completion(.failure(Error.notAuthenticated)) }
            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        
        let task = self.session.dataTask(with: request) { data, response, error in
            do
            {
                guard let data = data else
                {
                    completion(.failure(error!))
                    return
                }
                
                if let response = response as? HTTPURLResponse, response.statusCode == 401
                {
                    switch authorizationType
                    {
                    case .creator: completion(.failure(Error.invalidAccessToken))
                    case .none: completion(.failure(Error.notAuthenticated))
                    case .user:
                        self.refreshAccessToken { result in
                            switch result
                            {
                            case .failure(let error): completion(.failure(error))
                            case .success: self.send(request, authorizationType: authorizationType, completion: completion)
                            }
                        }
                    }
                    
                    return
                }
                
                let response = try JSONDecoder().decode(ResponseType.self, from: data)
                completion(.success(response))
            }
            catch
            {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
