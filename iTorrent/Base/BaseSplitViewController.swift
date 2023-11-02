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

    override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
        super.collapseSecondaryViewController(secondaryViewController, for: splitViewController)
    }

    override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        super.separateSecondaryViewController(for: splitViewController)
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
        while nvc.viewControllers.count > 1 {
            guard let vc = nvc.viewControllers.popLast()
            else { break }

            vcs.append(vc)

            if vc == detailViewController { break }
        }

        if !vcs.isEmpty {
            let snvc = UINavigationController.resolve()
            snvc.viewControllers = vcs.reversed()
            return snvc
        }

        return EmptyView().asController
    }
}

private extension BaseSplitViewController {
    struct EmptyView: View {
        var body: some View {
            Text("iTorrent")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
        }
    }
}
