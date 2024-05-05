//
//  GoogleAdsManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2024.
//

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

import Foundation

class GoogleAdsManager {
#if canImport(GoogleMobileAds)
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
#endif
}
