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
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var fileImageView: UIImageView!
    
    override func initSetup() {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        titleLabel.font = fontMetrics.scaledFont(for: font)

        switchView.addTarget(self, action: #selector(switcher), for: .valueChanged)
        separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
    }

    override func setup(with viewModel: VM) {
        setViewModel(viewModel)

        disposeBag.bind {
            viewModel.updatePublisher.sink { [unowned self] _ in
                reload()
            }
            viewModel.selected.sink { [unowned self] _ in
                if progressView.progress >= 1 {
                    shareAction()
                } else {
                    switchView.setOn(!switchView.isOn, animated: true)
                    switcher(switchView)
                }
            }
        }
        reload()
    }

    func shareAction() {
        let url = viewModel.path as NSURL
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if vc.popoverPresentationController != nil {
//                    vc.popoverPresentationController?.barButtonItem = shareButton
            vc.popoverPresentationController?.sourceView = shareButton
            vc.popoverPresentationController?.sourceRect = shareButton.frame
            vc.popoverPresentationController?.permittedArrowDirections = .any
        }
        viewController?.present(vc, animated: true)
    }

    @objc func switcher(_ sender: UISwitch) {
        viewModel.setPriority(sender.isOn ? .defaultPriority : .dontDownload)
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
        shareButton.isHidden = file.progress < 1
        switchView.isHidden = !shareButton.isHidden
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
            return nil
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
