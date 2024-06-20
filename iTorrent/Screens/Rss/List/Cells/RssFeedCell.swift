//
//  RssFeedCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import UIKit
import MvvmFoundation
import CombineCocoa

class RssFeedCell<VM: RssFeedCellViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var feedLogoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var newCounterLabel: UILabel!
    private lazy var editButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(systemName: "ellipsis.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium, scale: .large)), for: .normal)
        return button
    }()

    override func setup(with viewModel: VM) {
        disposeBag.bind {
            viewModel.$title.uiSink { [unowned self] title in
                titleLabel.text = title
            }
            viewModel.$description.uiSink { [unowned self] description in
                descriptionLabel.text = description
            }
            viewModel.$newCounter.uiSink { [unowned self] newCounter in
                newCounterLabel.text = "\(newCounter)"
                newCounterLabel.superview?.isHidden = newCounter == 0
            }
            viewModel.$feedLogo.uiSink { [unowned self] logo in
                feedLogoImageView.image = logo
            }
            editButton.tapPublisher.uiSink { _ in
                viewModel.openPreferences()
            }
            viewModel.popoverPreferenceNavigationTransaction.uiSink { [unowned self] from, to in
//                let nvc = UINavigationController.resolve()
//                let target = nvc
                let target = to
//                target.viewControllers = [to]
                target.modalPresentationStyle = .popover
                target.popoverPresentationController?.sourceView = editButton
                target.popoverPresentationController?.delegate = delegates
                target.popoverPresentationController?.permittedArrowDirections = [.up, .down, .left]
                from.present(target, animated: true)
            }
        }

        accessories = [
            .disclosureIndicator(displayed: .whenNotEditing),
            .customView(configuration: .init(customView: editButton, placement: .trailing(displayed: .whenEditing, at: { accessories in
                0
            }))),
            .reorder(),
            .multiselect()
        ]
    }

    private lazy var delegates = Delegates(parent: self)
}

private extension RssFeedCell {
    class Delegates: DelegateObject<RssFeedCell>, UIPopoverPresentationControllerDelegate {
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            .none
        }
    }
}
