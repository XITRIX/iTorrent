//
//  UnityAdsManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 20.05.2023.
//  Copyright © 2023  XITRIX. All rights reserved.
//

import Foundation
import UnityAds
import Bond

class UnityAdsManager: NSObject {
    private let gameId = "5284803"
    static let shared = UnityAdsManager()

    private var wasShowed: Bool = adWasShowedCondition()

    let interstitialPlacementId = "Interstitial_iOS"
    let bannerPlacementId = "Banner_iOS"

    let interstitialAdId = Observable<String?>(nil)

    private override init() {
        super.init()
        initializeAds()
    }

    private func showInterstitialAd(from viewController: UIViewController) {
        UnityAdsManager.shared.interstitialAdId.observeNext { [weak self] id in
            guard let self, let id else { return }
            UnityAds.show(viewController, placementId: id, showDelegate: self)
            self.bag.dispose()
        }.dispose(in: bag)
    }

    func showInterstitialAdIfNotShowed(from viewController: UIViewController) {
        guard !wasShowed else { return }
        showInterstitialAd(from: viewController)
    }
}

private extension UnityAdsManager {
    func initializeAds() {
        UnityAds.initialize(gameId, testMode: false, initializationDelegate: self)
    }

    static func adWasShowedCondition() -> Bool {
        let dateExpired: Bool

        if let lastShowedDate = UserPreferences.dateFSAdShown {
            let diffComponents = Calendar.current.dateComponents([.hour], from: lastShowedDate, to: Date())
            if let hours = diffComponents.hour {
                dateExpired = abs(hours) > (UserPreferences.patreonCredentials?.fsAdsHourPeriod ?? 24)
            } else {
                dateExpired = true
            }
        } else {
            dateExpired = true
        }

        return !dateExpired || UserPreferences.disableAds || (UserPreferences.patreonCredentials?.hideFSAds ?? true)
    }
}

extension UnityAdsManager: UnityAdsInitializationDelegate {
    func initializationComplete() {
        UnityAds.load(interstitialPlacementId, loadDelegate: self)
    }

    func initializationFailed(_ error: UnityAdsInitializationError, withMessage message: String) {
        print("Unity ADS: initialization failed with \nError: \(error) \nMessage: \(message)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.initializeAds()
        }
    }
}

extension UnityAdsManager: UnityAdsLoadDelegate {
    func unityAdsAdLoaded(_ placementId: String) {
        print("Unity ADS: ad with id: \(placementId), is loaded")
        switch placementId {
        case interstitialPlacementId:
            interstitialAdId.value = placementId
        default: break
        }
    }

    func unityAdsAdFailed(toLoad placementId: String, withError error: UnityAdsLoadError, withMessage message: String) {
        print("Unity ADS: loading ad with id: \(placementId), is failed with error: \(error) and message: \(message)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UnityAds.load(placementId, loadDelegate: self)
        }
    }
}

extension UnityAdsManager: UnityAdsShowDelegate {
    func unityAdsShowComplete(_ placementId: String, withFinish state: UnityAdsShowCompletionState) {
        print(" - UnityAdsShowDelegate unityAdsShowComplete \(placementId) \(state)")
        UserPreferences.dateFSAdShown = Date()
        wasShowed = true
    }

    func unityAdsShowFailed(_ placementId: String, withError error: UnityAdsShowError, withMessage message: String) {
        print(" - UnityAdsShowDelegate unityAdsShowFailed \(message) \(error)")
    }

    func unityAdsShowStart(_ placementId: String) {
        print(" - UnityAdsShowDelegate unityAdsShowStart \(placementId)")
    }

    func unityAdsShowClick(_ placementId: String) {
        print(" - UnityAdsShowDelegate unityAdsShowClick \(placementId)")
    }
}
