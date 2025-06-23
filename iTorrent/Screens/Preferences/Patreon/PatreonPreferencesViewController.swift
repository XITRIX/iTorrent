//
//  PatreonPreferencesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import Combine
import SafariServices
import UIKit

class PatreonPreferencesViewController<VM: PatreonPreferencesViewModel>: BaseViewController<VM> {
    @IBOutlet private var roundedViews: [UIView]!

    @IBOutlet private var creatorName: UILabel!
    @IBOutlet private var creatorDescription: UILabel!
    @IBOutlet private var creatorMessage: UILabel!

    @IBOutlet private var patronBox: UIView!
    @IBOutlet private var patronTitle: UILabel!
    @IBOutlet private var patronMessage: UILabel!

    @IBOutlet private var becomePatronButton: UIButton!
    @IBOutlet private var linkPatreonButton: UIButton!
    @IBOutlet private var linkPatreonLoading: UIActivityIndicatorView!

    @IBOutlet private var chatPin: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = %"preferences.donations.patreon"

        roundedViews.forEach {
#if os(visionOS)
            $0.layer.cornerRadius = 16
#else
            $0.layer.cornerRadius = 10
#endif
            $0.layer.cornerCurve = .continuous
        }

        creatorName.text = %"patreon.creator.name"
        creatorDescription.text = %"patreon.creator.description"
        creatorMessage.text = %"patreon.creator.message"

        patronMessage.text = %"patreon.patron.level"

        becomePatronButton.configuration?.attributedTitle = .init(%"patreon.action.patron", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline)]))
//        becomePatronButton.configuration?.title = %"patreon.action.patron"
//        becomePatronButton.setTitle(%"patreon.action.patron", for: .normal)

        binding()
        setupActions()

#if os(visionOS)
        chatPin.isHidden = true
#endif
    }
}

private extension PatreonPreferencesViewController {
    func binding() {
        disposeBag.bind {
            viewModel.linkButtonTitle.uiSink { [unowned self] title in
//                linkPatreonButton.setTitle(title, for: .normal)
                linkPatreonButton.configuration?.attributedTitle = .init(title, attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline)])) 
//                linkPatreonButton.configuration?.title = title
            }

            Publishers.combineLatest(
                viewModel.isPatronPublisher,
                viewModel.isFullVersionPublisher)
            { $0 || $1 }.uiSink { isShown in
                UIView.animate(withDuration: 0.3) { [self] in
                    patronBox.isHidden = !isShown
                }
            }

            viewModel.isPatronPublisher.uiSink { [unowned self] isPatron in
                UIView.animate(withDuration: 0.3) { [self] in
                    becomePatronButton.isHidden = isPatron
                }
            }

            viewModel.accountState.uiSink { [unowned self] state in
                if state == .loading {
                    linkPatreonLoading.startAnimating()
                } else {
                    linkPatreonLoading.stopAnimating()
                }
            }

            viewModel.versionTextPublisher.uiSink { [unowned self] title in
                patronTitle.text = title
            }
        }
    }

    func setupActions() {
        becomePatronButton.addAction(.init { [unowned self] _ in
            let safari = BaseSafariViewController(url: URL(string: "https://patreon.com/xitrix")!)
//#if !os(visionOS)
            safari.modalPresentationStyle = .pageSheet
//#endif
            present(safari, animated: true)
        }, for: .touchUpInside)

        linkPatreonButton.addAction(.init { [unowned self] _ in
            viewModel.linkPatreon(from: linkPatreonButton)
        }, for: .touchUpInside)
    }
}
