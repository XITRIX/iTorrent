//
//  BaseViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import MarqueeLabel
import MvvmFoundation
import UIKit

class BaseViewController<ViewModel: MvvmViewModelProtocol>: SAViewController<ViewModel> {
    var isToolbarItemsHidden: Bool { toolbarItems?.isEmpty ?? true }
    var useMarqueeLabel: Bool { true }

    override var title: String? {
        get { super.title }
        set {
            super.title = newValue
            titleLabel.text = newValue
            titleLabel.sizeToFit()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(visionOS)
        view.backgroundColor = nil
        #endif

        titleLabel.text = title
        #if !os(visionOS) // Not renders properly on VisionOS
        if useMarqueeLabel {
            navigationItem.titleView = titleLabel
            titleLabel.sizeToFit()
        }
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(isToolbarItemsHidden, animated: false)
    }

    private let titleLabel: MarqueeLabel = {
        let titleLabel = MarqueeLabel()
#if !os(visionOS)
        titleLabel.font = .preferredFont(forTextStyle: .headline)
#else
        titleLabel.font = .preferredFont(forTextStyle: .title1)
#endif
        titleLabel.fadeLength = 16
        titleLabel.adjustsFontForContentSizeCategory = true
        return titleLabel
    }()
}
