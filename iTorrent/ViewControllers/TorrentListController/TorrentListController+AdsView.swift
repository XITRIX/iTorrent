//
//  TorrentListController+AdsView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
import UIKit

extension TorrentListController {
    func initializeAds() {
        adsView.adUnitID = "ca-app-pub-3833820876743264/3158004742"
        adsView.rootViewController = self
        adsView.delegate = self
    }

    func viewWillAppearAds() {
        if !UserPreferences.disableAds, !adsLoaded {
            adsView.load(GADRequest())
        } else if !UserPreferences.disableAds, adsLoaded {
            adsView.isHidden = false
            tableView.contentInset.bottom = adsView.frame.height
            tableView.scrollIndicatorInsets.bottom = adsView.frame.height
        } else {
            adsView.isHidden = true
            tableView.contentInset.bottom = 0
            tableView.scrollIndicatorInsets.bottom = 0
        }
    }
}

extension TorrentListController: GADBannerViewDelegate {
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        adsLoaded = false

        bannerView.isHidden = true
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }

    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Add banner to view and add constraints as above.
        adsLoaded = true
        if !UserPreferences.disableAds {
            bannerView.isHidden = false
            tableView.contentInset.bottom = bannerView.frame.height
            tableView.scrollIndicatorInsets.bottom = bannerView.frame.height
        }
    }
}
#endif
