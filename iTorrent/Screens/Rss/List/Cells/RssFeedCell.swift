//
//  RssFeedCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import UIKit
import MvvmFoundation

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
            viewModel.$title.sink { [unowned self] title in
                titleLabel.text = title
            }
            viewModel.$description.sink { [unowned self] description in
                descriptionLabel.text = description
            }
            viewModel.$newCounter.sink { [unowned self] newCounter in
                newCounterLabel.text = "\(newCounter)"
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

//    edit
}
