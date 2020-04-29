//
//  FullscreenAd.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import GoogleMobileAds
import UIKit

class FullscreenAd: NSObject {
    var interstitial: GADInterstitial!
    static let shared = FullscreenAd(id: "ca-app-pub-3833820876743264/8966239009")

    var showed = UserPreferences.disableAds || (UserPreferences.patreonCredentials?.hideFSAds ?? true)

    init(id: String) {
        super.init()

        interstitial = GADInterstitial(adUnitID: id)
        interstitial.delegate = self
    }

    func load() {
        if !showed {
            interstitial.load(GADRequest())
            showed = true
        }
    }
}

extension FullscreenAd: GADInterstitialDelegate {
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: UIApplication.shared.keyWindow!.rootViewController!)
        }
    }
}
