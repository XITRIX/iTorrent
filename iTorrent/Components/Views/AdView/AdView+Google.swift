//
//  AdView+Google.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/05/2024.
//

#if canImport(GoogleMobileAds)
import Foundation
import GoogleMobileAds

class AdView: BaseView {
    override func setup() {
        preservesSuperviewLayoutMargins = true

        bannerView = GADBannerView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerView)

        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor),
            topAnchor.constraint(equalTo: bannerView.topAnchor),
            bannerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            zeroHeightConstraint
        ])

        bannerView.adUnitID = "ca-app-pub-1735670339238689/6645306885"
        bannerView.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = safeAreaLayoutGuide.layoutFrame.width
        guard lastWidth != width, width != 0 else { return }
        lastWidth = width

        adsLoaded = false
        bannerView.rootViewController = viewController
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        bannerView.load(GADRequest())
    }

    private lazy var zeroHeightConstraint: NSLayoutConstraint = { heightAnchor.constraint(equalToConstant: 0) }()
    private var lastWidth: CGFloat = 0
    private var bannerView: GADBannerView!
    private var adsLoaded = false {
        didSet { zeroHeightConstraint.isActive = !adsLoaded }
    }
}

extension AdView: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("bannerViewDidReceiveAd")
        adsLoaded = true
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        adsLoaded = false
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewDidDismissScreen")
    }
}
#endif
