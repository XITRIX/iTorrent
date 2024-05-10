//
//  API.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/05/2024.
//

import Foundation

extension PatreonService {
    enum Error: LocalizedError {
        case unknown
        case notAuthenticated
        case invalidAccessToken
        case noCredentials

        var errorDescription: String? {
            switch self {
            case .unknown: return NSLocalizedString("An unknown error occurred.", comment: "")
            case .notAuthenticated: return NSLocalizedString("No connected Patreon account.", comment: "")
            case .invalidAccessToken: return NSLocalizedString("Invalid access token.", comment: "")
            case .noCredentials: return NSLocalizedString("No credentials.", comment: "")
            }
        }
    }

    enum AuthorizationType {
        case none
        case user
        case creator
    }

    enum AnyResponse: Decodable {
        case tier(TierResponse)
        case benefit(BenefitResponse)

        enum CodingKeys: String, CodingKey {
            case type
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let type = try container.decode(String.self, forKey: .type)
            switch type {
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
