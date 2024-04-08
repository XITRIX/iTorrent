//
//  RssChannelItemCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import UIKit
import MvvmFoundation

class RssChannelItemCell<VM: RssChannelItemCellViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var newIndicatorView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!
    
    override func initSetup() {
        separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        accessories = [.disclosureIndicator()]
    }

    override func setup(with viewModel: VM) {
        disposeBag.bind {
            viewModel.$isNew.sink { [newIndicatorView] isNew in
                newIndicatorView?.isHidden = !isNew
            }
            viewModel.$title.sink { [titleLabel] text in
                titleLabel?.text = text
            }
            
        }
    }
}
