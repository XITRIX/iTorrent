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
import UnityAds

extension TorrentListController {
    func initializeAds() {
//        adsView.adUnitID = "ca-app-pub-1881668817168934/1513806341"
//        adsView.rootViewController = self
//        adsView.delegate = self

        setupUnityAds()
    }

    func viewWillAppearAds() {
        guard !UserPreferences.disableAds,
              !(UserPreferences.patreonCredentials?.hideBannerAds ?? true)
        else {
            adsView.isHidden = true
            unityAdsView.isHidden = true

            tableView.contentInset.bottom = 0
            tableView.scrollIndicatorInsets.bottom = 0

            return
        }

        if adsLoaded {
//            adsView.isHidden = false
            unityAdsView.isHidden = false

            tableView.contentInset.bottom = unityAdsView.frame.height
            tableView.scrollIndicatorInsets.bottom = unityAdsView.frame.height
        } else {
//            adsView.load(GADRequest())
            unityAdsView.isHidden = true
            unityAdsView.load()
        }
    }

    func setupUnityAds() {
        unityAdsView = UADSBannerView(placementId: UnityAdsManager.shared.bannerPlacementId, size: CGSize(width: 320, height: 50))
        unityAdsView.translatesAutoresizingMaskIntoConstraints = false
        unityAdsView.delegate = self
        unityAdsView.isHidden = true
        unityAdsView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        adsStackView.addArrangedSubview(unityAdsView)
    }
}

extension TorrentListController: GADBannerViewDelegate {
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print(error.localizedDescription)
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

extension TorrentListController: UADSBannerViewDelegate {
    func bannerViewDidError(_ bannerView: UADSBannerView!, error: UADSBannerError!) {
        print(error.localizedDescription)
        adsLoaded = false

        unityAdsView.isHidden = true
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }

    func bannerViewDidLoad(_ bannerView: UADSBannerView!) {
        adsLoaded = true
        if !UserPreferences.disableAds {
            unityAdsView.isHidden = false
            tableView.contentInset.bottom = 50
            tableView.scrollIndicatorInsets.bottom = 50
        }
    }

    func bannerViewDidClick(_ bannerView: UADSBannerView!) {}

    func bannerViewDidLeaveApplication(_ bannerView: UADSBannerView!) {}
}
