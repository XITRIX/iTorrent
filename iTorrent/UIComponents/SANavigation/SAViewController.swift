//
//  SAViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//
import UIKit
import MVVMFoundation

public protocol NavigationProtocol: UIViewController {
    var swipeAnywhereDisabled: Bool { get }
    var toolBarIsHidden: Bool? { get }
    var navigationBarIsHidden: Bool? { get set }

    var hidesTopBar: Bool { get set }
    var hidesBottomBar: Bool { get set }

    func updateNavigationControllerState(animated: Bool)
}

public extension NavigationProtocol {
    var swipeAnywhereDisabled: Bool { false }
}

open class SAViewController<ViewModel: MvvmViewModelProtocol>: MvvmViewController<ViewModel>, NavigationProtocol {
    private var isPresented: Bool = false

    open var hidesTopBar: Bool = false
    open var hidesBottomBar: Bool = false

    open var swipeAnywhereDisabled: Bool {
        false
    }

    open var toolBarIsHidden: Bool? {
        nil
    }

    open var navigationBarIsHidden: Bool? = false {
        didSet {
            if isPresented {
                updateNavigationControllerState(animated: true)
            }
        }
    }

    open override func setupView() {
        super.setupView()
        themeChanged()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationControllerState(animated: animated)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
           nav.viewControllers.last == self
        {
            nav.locker = false
        }
        isPresented = true
        updateNavigationControllerState(animated: false)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPresented = false
    }

    open func updateNavigationControllerState(animated: Bool = true) {
        if let toolBarIsHidden = toolBarIsHidden,
           navigationController?.isToolbarHidden != toolBarIsHidden
        {
            navigationController?.setToolbarHidden(toolBarIsHidden, animated: animated)
        }

        if let navigationBarIsHidden = navigationBarIsHidden,
           navigationController?.isNavigationBarHidden != navigationBarIsHidden
        {
            navigationController?.setNavigationBarHidden(navigationBarIsHidden, animated: animated)
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                themeChanged()
            }
        }
    }

    open func themeChanged() {}
}

open class SATableViewController<ViewModel: MvvmViewModelProtocol>: MvvmTableViewController<ViewModel>, NavigationProtocol {
    open var swipeAnywhereDisabled: Bool {
        false
    }

    open var toolBarIsHidden: Bool? {
        nil
    }

    open var navigationBarIsHidden: Bool? = false

    open var hidesTopBar: Bool = false
    open var hidesBottomBar: Bool = false

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
           nav.viewControllers.last == self
        {
            nav.locker = false
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationControllerState()
    }

    open func updateNavigationControllerState(animated: Bool = true) {
        if let toolBarIsHidden = toolBarIsHidden {
            navigationController?.setToolbarHidden(toolBarIsHidden, animated: animated)
        }

        if let navigationBarIsHidden = navigationBarIsHidden {
            navigationController?.setNavigationBarHidden(navigationBarIsHidden, animated: animated)
        }
    }
}
