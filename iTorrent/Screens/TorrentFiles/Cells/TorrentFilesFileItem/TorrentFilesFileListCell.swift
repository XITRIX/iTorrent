//
//  TorrentFilesFileListCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import LibTorrent
import MvvmFoundation
import UIKit

class TorrentFilesFileListCell<VM: TorrentFilesFileItemViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var switchView: UISwitch!
    @IBOutlet private var fileImageView: UIImageView!
    
    override func initSetup() {
        let font = UIFont.systemFont(ofSize: titleLabel.font!.pointSize, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        titleLabel.font = fontMetrics.scaledFont(for: font)
    }

    override func setup(with viewModel: VM) {
        setViewModel(viewModel)
        disposeBag.bind {
            viewModel.updatePublisher.sink { [unowned self] _ in
                reload()
            }
        }
        reload()
    }
}

private extension TorrentFilesFileListCell {
    func reload() {
        let file = viewModel.file

        let percent = "\(String(format: "%.2f", file.progress * 100))%"
        titleLabel.text = file.name
        subtitleLabel.text = "\(file.downloaded.bitrateToHumanReadable) / \(file.size.bitrateToHumanReadable) (\(percent))"
        progressView.progress = file.progress
        fileImageView.image = .icon(forFileURL: viewModel.path)
        switchView.isOn = file.priority != .dontDownload
        switchView.onTintColor = file.priority.color
        invalidateIntrinsicContentSize()
    }
}

private extension FileEntry {
    var progress: Float {
        Float(downloaded) / Float(size)
    }
}

private extension FileEntry.Priority {
    var color: UIColor? {
        switch self {
        case .dontDownload:
            return .systemGray
        case .defaultPriority:
            return nil
        case .lowPriority:
            return .systemRed
        case .topPriority:
            return .systemCyan
        default:
            return nil
        }
    }
}
