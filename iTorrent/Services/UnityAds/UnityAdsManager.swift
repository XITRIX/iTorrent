//
//  UnityAdsManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.04.2024.
//

import Combine
import Foundation
import UnityAds
import MvvmFoundation

@MainActor
class UnityAdsManager: NSObject {
    private static let gameId = "5284803"
    private static let interstitialPlacementId = "Interstitial_iOS"
    static let bannerPlacementId = "Banner_iOS"

    private var wasShowed: Bool = adWasShowedCondition()

    @Published var interstitialAdId: String?

    override init() {
        super.init()
        registerUnity()
    }
}

extension UnityAdsManager: UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate {
    func initializationComplete() {
        UnityAds.load(Self.interstitialPlacementId, loadDelegate: self)
    }

    func initializationFailed(_ error: UnityAdsInitializationError, withMessage message: String) {
        print("Unity ADS: initialization failed with \nError: \(error) \nMessage: \(message)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.registerUnity()
        }
    }

    func unityAdsAdLoaded(_ placementId: String) {
        print("Unity ADS: ad with id: \(placementId), is loaded")
        switch placementId {
        case Self.interstitialPlacementId:
            interstitialAdId = placementId
        default: break
        }
    }

    func unityAdsAdFailed(toLoad placementId: String, withError error: UnityAdsLoadError, withMessage message: String) {
        print("Unity ADS: loading ad with id: \(placementId), is failed with error: \(error) and message: \(message)")
        Task {
            try await Task.sleep(for: .seconds(2))
            UnityAds.load(placementId, loadDelegate: self)
        }
    }

    func unityAdsShowComplete(_ placementId: String, withFinish state: UnityAdsShowCompletionState) {
        print(" - UnityAdsShowDelegate unityAdsShowComplete \(placementId) \(state)")
//        UserPreferences.dateFSAdShown = Date()
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

private extension UnityAdsManager {
    func registerUnity() {
        UnityAds.initialize(Self.gameId, testMode: false, initializationDelegate: self)
    }

    static func adWasShowedCondition() -> Bool {
        return false
//        let dateExpired: Bool
//
//        if let lastShowedDate = UserPreferences.dateFSAdShown {
//            let diffComponents = Calendar.current.dateComponents([.hour], from: lastShowedDate, to: Date())
//            if let hours = diffComponents.hour {
//                dateExpired = abs(hours) > (UserPreferences.patreonCredentials?.fsAdsHourPeriod ?? 24)
//            } else {
//                dateExpired = true
//            }
//        } else {
//            dateExpired = true
//        }
//
//        return !dateExpired || UserPreferences.disableAds || (UserPreferences.patreonCredentials?.hideFSAds ?? true)
    }
}
