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
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!
    
    override func initSetup() {
        separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        accessories = [.disclosureIndicator()]
    }

    override func setup(with viewModel: VM) {
        disposeBag.bind {
            viewModel.$isNew.uiSink { [newIndicatorView] isNew in
                newIndicatorView?.isHidden = !isNew
            }
            viewModel.$isReaded.uiSink { [titleLabel] isReaded in
                titleLabel?.textColor = isReaded ? .secondaryLabel : .label
            }
            viewModel.$title.uiSink { [titleLabel] text in
                titleLabel?.text = text
            }
            viewModel.$date.uiSink { [timeLabel] text in
                timeLabel?.text = text
                timeLabel?.isHidden = text.isNilOrEmpty
            }
            viewModel.$subtitle.uiSink { [subtitleLabel] text in
                subtitleLabel?.text = text
                subtitleLabel?.isHidden = text.isNilOrEmpty
            }
        }
    }
}
