//
//  AdView+Meta.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2024.
//

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
import Foundation

class AdView: BaseView {
    private lazy var adView: FBAdView = makeAdView()
}

extension AdView: FBAdViewDelegate {}

private extension AdView {
    func makeAdView() -> FBAdView {
        let adView = FBAdView(placementID: "YOUR_PLACEMENT_ID", adSize: kFBAdSizeHeight50Banner, rootViewController: viewController)
        adView.frame = CGRect(x: 0, y: 0, width: 320, height: 250)
        adView.delegate = self
        adView.loadAd()
        return adView
    }
}
#endif
