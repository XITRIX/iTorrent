//
//  FullscreenAd.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
import UIKit

class FullscreenAd: NSObject {
    private var interstitial: GADInterstitialAd?
    static let shared = FullscreenAd(id: "ca-app-pub-3833820876743264/8966239009")

    var showed = UserPreferences.disableAds || (UserPreferences.patreonCredentials?.hideFSAds ?? true)
    private let id: String

    init(id: String) {
        self.id = id
        super.init()
    }

    func load() {
        if !showed {
            showed = true
            GADInterstitialAd.load(withAdUnitID: id, request: GADRequest()) { [weak self] interstitial, error in
                guard let self,
                    error == nil
                else {
                    self?.showed = false
                    return
                }

                self.interstitial = interstitial
                interstitial?.present(fromRootViewController: UIApplication.shared.keyWindow!.rootViewController!)
            }
        }
    }
}
#endif
