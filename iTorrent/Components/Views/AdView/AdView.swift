//
//  AdView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.04.2024.
//

import UIKit

#if canImport(UnityAds)
import UnityAds
#endif

class AdView: BaseView {
#if canImport(UnityAds)
    override func setup() {
        let bannerView = UADSBannerView(placementId: UnityAdsManager.bannerPlacementId, size: CGSize(width: 320, height: height))
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.delegate = self
        addSubview(bannerView)

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: bannerView.leadingAnchor),
            topAnchor.constraint(equalTo: bannerView.topAnchor),
            bannerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])

        bannerView.load()
    }
#endif

    var heightConstraint: NSLayoutConstraint!
    let height: Double = 50

    var adsLoaded = false {
        didSet { heightConstraint.constant = adsLoaded ? height : 0 }
    }
}

#if canImport(UnityAds)
extension AdView: UADSBannerViewDelegate {
    func bannerViewDidError(_ bannerView: UADSBannerView!, error: UADSBannerError!) {
        print("Unity ADS: loading ad with id: \(UnityAdsManager.bannerPlacementId), is failed with error: \(error.localizedDescription)")
        adsLoaded = false
        isHidden = true
    }

    func bannerViewDidLoad(_ bannerView: UADSBannerView!) {
        print("Unity ADS: ad with id: \(UnityAdsManager.bannerPlacementId), is loaded")
        adsLoaded = true
//        if !UserPreferences.disableAds {
//            unityAdsView.isHidden = false
//        }
    }

    func bannerViewDidClick(_ bannerView: UADSBannerView!) {}

    func bannerViewDidLeaveApplication(_ bannerView: UADSBannerView!) {}
}
#endif
