//
//  PatreonCredentials.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 11.05.2024.
//

import Foundation

struct PatreonCredentials: Codable {
    struct Benefits: Codable {
        var fullVersion: [String]
    }

    var clientID: String
    var clientSecret: String
    var patreonCreatorAccessToken: String
    var campaignID: String
    var hideFSAds: Bool
    var hideBannerAds: Bool
    var fsAdsHourPeriod: Int
    var benefits: Benefits
}
