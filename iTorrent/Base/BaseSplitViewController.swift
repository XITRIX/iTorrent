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
        if let nvc = vc as? UINavigationController {
            if isCollapsed {
                if let vc = nvc.topViewController {
                    detailViewController = vc
                    super.showDetailViewController(vc, sender: sender)
                }
            } else {
                detailViewController = nvc.topViewController
                super.showDetailViewController(nvc, sender: sender)
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
            viewControllers[1] = emptyView
        }
    }

    func showEmptyDetail() -> Bool {
        guard !isCollapsed else { return false }
        viewControllers[1] = emptyView
        return true
    }
}

private extension BaseSplitViewController {
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
        nvc.isToolbarHidden = snvc.isToolbarHidden
        snvc.viewControllers = []
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

        nvc.isToolbarHidden = nvc.viewControllers.last?.toolbarItems?.isEmpty ?? true

        if !vcs.isEmpty {
            let snvc = UINavigationController.resolve()
            snvc.viewControllers = vcs.reversed()
            snvc.isToolbarHidden = snvc.viewControllers.last?.toolbarItems?.isEmpty ?? true
            return snvc
        }

        return EmptyView().asController
    }
}

private extension BaseSplitViewController {
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
