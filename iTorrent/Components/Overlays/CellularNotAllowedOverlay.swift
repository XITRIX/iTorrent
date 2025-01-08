//
//  CellularNotAllowedOverlay.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import Combine
import MvvmFoundation
import UIKit

class PassthrowView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self { return nil }
        return view
    }
}

class OverlayWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self { return nil }
        return view
    }

    override func makeKey() {}
}

class OverlayViewController: UIViewController {
    override func loadView() {
        view = PassthrowView()
    }
}

final class CellularNotAllowedOverlay: @unchecked Sendable {
    private let overlayView = MessageOverlayView()
    private let overlayViewController = OverlayViewController()
    private lazy var overlayWindow: UIWindow = initOverlayWindow()
    private var currentOverlayTask: Task<Void, Error>?
    private var bottomConstraint: NSLayoutConstraint!
    private let disposeBag = DisposeBag()

    init() {
        setup()
    }

    @Injected private var networkMonitoringService: NetworkMonitoringService
    @Injected private var preferencesStorage: PreferencesStorage
}

private extension CellularNotAllowedOverlay {
    func setup() {
        overlayView.image = .init(systemName: "antenna.radiowaves.left.and.right.slash")
        overlayView.title = %"overlay.cellular.title"
        overlayView.message = %"overlay.cellular.message"

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayViewController.view.addSubview(overlayView)

        bottomConstraint = overlayViewController.view.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor)

        NSLayoutConstraint.activate([
            overlayViewController.view.layoutMarginsGuide.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            overlayViewController.view.layoutMarginsGuide.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: overlayViewController.view.layoutMarginsGuide.trailingAnchor),
            bottomConstraint
        ])

        overlayView.clickEvent = { @MainActor [unowned self] in
            showCellularPreferences()
            hideOverlay()
        }

        disposeBag.bind {
            Publishers.combineLatest(networkMonitoringService.$isCellularAvailable,
                                     networkMonitoringService.$availableInterfaces,
                                     networkMonitoringService.$cellularState,
                                     preferencesStorage.$isCellularEnabled,
                                     NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            { isCellularAvailable, interfaces, cellularDeviceAllowed, cellularAppAllowed, _ in

                // Show if restricted by app or device
                guard cellularDeviceAllowed == .restricted || !cellularAppAllowed
                else { return false }

                // Show if primary device is Cellular
                guard isCellularAvailable && interfaces.isEmpty else { return false }

                return true
            }.receive(on: UIScheduler.shared)
                .debounce(for: .seconds(1), scheduler: UIScheduler.shared)
                .throttle(for: .seconds(4), scheduler: UIScheduler.shared, latest: false)
                .sink { [unowned self] shouldShowOverlay in
                    guard shouldShowOverlay else { return }

                    currentOverlayTask?.cancel()
                    currentOverlayTask = Task { @MainActor in
                        showOverlay()
                        try await Task.sleep(for: .seconds(4))
                        hideOverlay()
                    }
                }
        }
    }

    func showOverlay() {
        overlayWindow.isHidden = false

        overlayViewController.view.setNeedsLayout()
        overlayViewController.view.layoutIfNeeded()

        if let viewController = UIApplication.shared.keySceneWindow.rootViewController?.topPresented,
           let svc = viewController as? UISplitViewController,
           let topVC = svc.detailNavigationController?.topViewController
        {
            bottomConstraint.constant = max(30, topVC.view.layoutMargins.bottom - overlayView.frame.height / 2)
        } else {
            bottomConstraint.constant = 30
        }


        overlayView.frame.origin.y = overlayViewController.view.frame.height
        overlayViewController.view.setNeedsLayout()

        overlayWindow.tintColor = preferencesStorage.tintColor

        if #available(iOS 17.0, *) {
            UIView.animate(springDuration: 0.3, bounce: 0.4, initialSpringVelocity: 0.3, delay: 0, options: []) {
                overlayViewController.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.3) { [self] in
                overlayViewController.view.layoutIfNeeded()
            }
        }
    }

    func hideOverlay() {
        UIView.animate(withDuration: 0.3) { [self] in
            overlayView.frame.origin.y = overlayViewController.view.frame.height
        } completion: { [self] _ in
            overlayWindow.isHidden = true
        }
    }

    @MainActor
    func showCellularPreferences() {
        // Open iOS settings app, if restricted on system level
        if networkMonitoringService.cellularState == .restricted,
            let url = URL(string: UIApplication.openSettingsURLString)
        {
            UIApplication.shared.open(url)
            return
        }

        // Otherwise open iTorrent's Preferences
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = scene.keyWindow,
              let viewController = window.rootViewController?.topPresented
        else { return }

        let networkVC = ConnectionPreferencesViewModel.resolveVC()
        networkVC.navigationItem.trailingItemGroups = [.fixedGroup(items: [
            .init(systemItem: .close, primaryAction: .init { [unowned networkVC] _ in
                networkVC.dismiss(animated: true)
            })
        ])]

        let nvc = UINavigationController.resolve()
        nvc.setViewControllers([networkVC], animated: false)
        viewController.present(nvc, animated: true)
    }

    func initOverlayWindow() -> UIWindow {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { fatalError("Impossible case") }

        let overlayWindow = OverlayWindow(windowScene: windowScene)
        overlayWindow.rootViewController = overlayViewController
        overlayWindow.windowLevel = .alert

        return overlayWindow
    }
}
