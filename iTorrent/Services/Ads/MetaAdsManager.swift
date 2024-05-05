//
//  MetaAdsManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2024.
//

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
#endif
import Foundation

class MetaAdsManager {
#if canImport(FBAudienceNetwork)
    init() {
        FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)
        FBAdSettings.setAdvertiserTrackingEnabled(true)
    }
#endif
}
