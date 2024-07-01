//
//  BaseViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import MarqueeLabel
import MvvmFoundation
import UIKit

protocol ToolbarHidingProtocol {
    var isToolbarItemsHidden: Bool { get }
}

class BaseViewController<ViewModel: MvvmViewModelProtocol>: SAViewController<ViewModel>, ToolbarHidingProtocol {
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
        titleLabel.textAlignment = .center
        return titleLabel
    }()
}

class BaseHostingViewController<View: MvvmSwiftUIViewProtocol>: SAHostingViewController<View>, ToolbarHidingProtocol {
    var isToolbarItemsHidden: Bool { toolbarItems?.isEmpty ?? true }
    var useMarqueeLabel: Bool { true }

//    override var title: String? {
//        get { super.title }
//        set {
//            super.title = newValue
//            titleLabel.text = newValue
//            titleLabel.sizeToFit()
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(visionOS)
        view.backgroundColor = nil
        #endif

//        #if !os(visionOS) // Not renders properly on VisionOS
//        if useMarqueeLabel {
//            navigationItem.titleView = titleLabel
//            titleLabel.sizeToFit()
//        }
//        #endif

        title = rootView.title
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(isToolbarItemsHidden, animated: false)

        if navigationController?.viewControllers.count == 1 {
            navigationItem.trailingItemGroups = [.fixedGroup(items: [
                UIBarButtonItem(systemItem: .close, primaryAction: .init { [unowned self] _ in
                    dismiss(animated: true)
                })
            ])]
        }
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
        titleLabel.textAlignment = .center
        return titleLabel
    }()
}
