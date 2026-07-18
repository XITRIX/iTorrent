//
//  BaseSplitViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01/11/2023.
//

import SwiftUI

class BaseSplitViewController: UISplitViewController {
    private weak var detailViewController: UIViewController?
    private lazy var emptyView = EmptyView().asController

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
//        preferredSplitBehavior = .tile

        #if os(visionOS)
        let nvc = UINavigationController.resolve()
        nvc.viewControllers = [emptyView]
        showDetailViewController(nvc, sender: self)
        #else
        if !isCollapsed {
            showDetailViewController(emptyView, sender: self)
        }
        #endif
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        guard canShowDetailViewController else { return }

        if let nvc = vc as? UINavigationController {
            if isCollapsed {
                if let vc = nvc.topViewController {
                    detailViewController = vc
                    super.showDetailViewController(vc, sender: sender)
                }
            } else {
                guard let detail = nvc.topViewController else { return }
                detailViewController = detail

                if let secondaryNavigationController,
                   secondaryNavigationController !== nvc
                {
                    nvc.setViewControllers([], animated: false)
                    secondaryNavigationController.setToolbarHidden(true, animated: false)
                    secondaryNavigationController.setViewControllers([detail], animated: false)
                    synchronizeToolbarVisibility(of: secondaryNavigationController)
                } else {
                    super.showDetailViewController(nvc, sender: sender)
                }
            }
        } else {
            if isCollapsed {
                detailViewController = vc
                super.showDetailViewController(vc, sender: sender)
            } else {
                if let nvc = secondaryNavigationController {
                    nvc.topViewController?.show(vc, sender: sender)
                } else {
                    let nvc = UINavigationController.resolve()
                    nvc.viewControllers = [vc]
                    detailViewController = vc
                    super.showDetailViewController(nvc, sender: sender)
                }
            }
        }
    }

    override func pop(animated: Bool, sender: Any? = nil) {
        guard let vc = sender as? UIViewController,
              !isCollapsed
        else { return super.pop(animated: animated, sender: sender) }

        if vc == secondaryNavigationController?.viewControllers.first {
            _ = showEmptyDetail()
        }
    }

    func showEmptyDetail() -> Bool {
        guard !isCollapsed else { return false }

        detailViewController = nil
        if let secondaryNavigationController {
            secondaryNavigationController.setToolbarHidden(true, animated: false)
            secondaryNavigationController.setViewControllers([emptyView], animated: false)
            synchronizeToolbarVisibility(of: secondaryNavigationController)
        } else {
            viewControllers[1] = emptyView
        }
        return true
    }
}

extension UISplitViewController {
    var detailNavigationController: UINavigationController? {
        secondaryNavigationController ?? primaryNavigationController
    }
}

private extension UISplitViewController {
    var primaryNavigationController: UINavigationController? {
        viewControllers.first as? UINavigationController
    }

    var secondaryNavigationController: UINavigationController? {
        guard viewControllers.count > 1 else { return nil }
        return viewControllers[1] as? UINavigationController
    }
}

extension BaseSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let nvc = primaryViewController as? UINavigationController,
              let snvc = secondaryViewController as? UINavigationController
        else { return true }

        nvc.viewControllers += snvc.viewControllers.filter { $0 != emptyView }
        snvc.viewControllers = []
        synchronizeToolbarVisibility(of: nvc)
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard let nvc = primaryViewController as? UINavigationController
        else { return nil }

        var vcs: [UIViewController] = []
        let original = nvc.viewControllers
        var secondStackFound = false
        while nvc.viewControllers.count > 1 {
            guard let vc = nvc.viewControllers.popLast()
            else { break }

            vcs.append(vc)

            if vc == detailViewController {
                secondStackFound = true
                break
            }
        }

        if !secondStackFound {
            nvc.viewControllers = original
            vcs = []
        }

        synchronizeToolbarVisibility(of: nvc)

        if !vcs.isEmpty {
            let snvc = UINavigationController.resolve()
            snvc.viewControllers = vcs.reversed()
            synchronizeToolbarVisibility(of: snvc)

            return snvc
        }

        return EmptyView().asController
    }
}

private extension BaseSplitViewController {
    func synchronizeToolbarVisibility(of navigationController: UINavigationController) {
        applyToolbarVisibility(to: navigationController)

        // Split-view adaptation can overwrite the value after the delegate
        // callback, so apply it once more after UIKit installs the new columns.
        DispatchQueue.main.async { [weak self, weak navigationController] in
            guard let self, let navigationController else { return }
            self.applyToolbarVisibility(to: navigationController)
        }
    }

    func applyToolbarVisibility(to navigationController: UINavigationController) {
        let topViewController = navigationController.topViewController
        let isHidden = (topViewController as? ToolbarHidingProtocol)?.isToolbarItemsHidden
            ?? topViewController?.toolbarItems?.isEmpty
            ?? true
        navigationController.setToolbarHidden(isHidden, animated: false)
    }

    var canShowDetailViewController: Bool {
        guard transitionCoordinator == nil else { return false }

        let navigationController = isCollapsed ? primaryNavigationController : secondaryNavigationController
        if let navigationController = navigationController as? SANavigationController {
            return navigationController.canPerformNavigationTransition
        }

        return navigationController?.transitionCoordinator == nil
    }

    struct EmptyView: View {
        var body: some View {
            Image(.iTorrentLogo)
                .foregroundStyle(Color.secondary)
                .ignoresSafeArea()
        }
    }
}

#Preview(body: {
    BaseSplitViewController.EmptyView()
})
