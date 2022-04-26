//
//  TorrentDelailsProgressCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 26.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentDelailsProgressCell: MvvmTableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var partialProgress: SegmentedProgressView!
    @IBOutlet var overallProgress: SegmentedProgressView!

    func setup(with model: TorrentDelailsProgressViewModel) {
        bind(in: reuseBag) {
            model.$title => titleLabel
            model.$overallProgress.map { [$0] } => overallProgress
            model.$partialProgress => partialProgress
        }
    }
}
