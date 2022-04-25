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

    @Bindable var title: String?
    @Bindable var progressText: String?
    @Bindable var statusText: String?
    @Bindable var progress: Float = 0

    override func binding() {
        bind(in: reuseBag) {
            $title.bind(to: titleLabel)
            $progressText.bind(to: progressLabel)
            $statusText.bind(to: statusLabel.reactive.text)
            $progress.bind(to: progressView.reactive.progress)
        }
    }

    func setup(with torrent: TorrentsListTorrentModel) {
        titleLabel.font = titleLabel.font.bold()
        bind(in: reuseBag) {
            torrent.$title => $title
            torrent.$progressText => $progressText
            torrent.$statusText => $statusText
            torrent.$progress => $progress
        }
    }
}

//private extension Torrent.Progress {
//    var description: String {
//        let percentString = String(format: "%0.2f%%", progress * 100)
//        let totalWantedString = ByteCountFormatter.string(fromByteCount: Int64(totalWanted), countStyle: .binary)
//        let totalWantedDoneString = ByteCountFormatter.string(fromByteCount: Int64(totalWantedDone), countStyle: .binary)
//
//        return "\(totalWantedDoneString) of \(totalWantedString) (\(percentString))"
//    }
//}
