//
//  TorrentsListTorrentCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.03.2022.
//

import MVVMFoundation
import ReactiveKit
import UIKit

class TorrentsListTorrentCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var progressLabel: UILabel!
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!

    func setup(with torrent: TorrentsListTorrentModel) {
        titleLabel.font = titleLabel.font.bold()
        bind(in: reuseBag) {
            torrent.title => titleLabel
            torrent.progressText => progressLabel
            torrent.statusText => statusLabel.reactive.text
            torrent.progress => progressView.reactive.progress
        }
    }
}
