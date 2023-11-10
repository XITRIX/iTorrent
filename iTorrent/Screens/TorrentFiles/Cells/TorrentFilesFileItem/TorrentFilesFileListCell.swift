//
//  TorrentFilesFileListCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import LibTorrent
import MvvmFoundation
import QuickLook
import UIKit

class TorrentFilesFileListCell<VM: FileItemViewModelProtocol>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var switchView: UISwitch!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var fileImageView: UIImageView!
    @IBOutlet private var noProgressConstraint: NSLayoutConstraint!

    private lazy var delegates = Delegates(parent: self)

    override func initSetup() {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        titleLabel.font = fontMetrics.scaledFont(for: font)

        switchView.addTarget(self, action: #selector(switcher), for: .valueChanged)
        separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true

        shareButton.showsMenuAsPrimaryAction = true
        shareButton.menu = UIMenu(children: [
            UIAction(title: "Open") { [unowned self] _ in
                previewAction()
            },
            UIAction(title: "Share", image: .init(systemName: "square.and.arrow.up")) { [unowned self] _ in
                shareAction()
            },
            UIAction(title: "Show in Files", image: .init(systemName: "folder")) { [unowned self] _ in
                showInFiles()
            }
        ])
    }

    override func setup(with viewModel: VM) {
        setViewModel(viewModel)

        progressView.isHidden = !viewModel.showProgress
        noProgressConstraint.isActive = !viewModel.showProgress

        disposeBag.bind {
            viewModel.updatePublisher.sink { [unowned self] _ in
                reload()
            }
            viewModel.selected.sink { [unowned self] _ in
                if progressView.progress >= 1 {
                    previewAction()
                } else {
                    switchView.setOn(!switchView.isOn, animated: true)
                    switcher(switchView)
                }
            }
        }
        reload()
    }

    func previewAction() {
        let vc = QLPreviewController()
        vc.dataSource = delegates
        viewController?.present(vc, animated: true)
    }

    func shareAction() {
        let url = viewModel.path as NSURL
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if vc.popoverPresentationController != nil {
            vc.popoverPresentationController?.sourceView = shareButton
            vc.popoverPresentationController?.sourceRect = shareButton.frame
            vc.popoverPresentationController?.permittedArrowDirections = .any
        }
        viewController?.present(vc, animated: true)
    }

    func showInFiles() {
        let path = viewModel.path.deletingLastPathComponent()
        var components = URLComponents(url: path as URL, resolvingAgainstBaseURL: false)
        components?.scheme = "shareddocuments"
        if let url = components?.url {
            UIApplication.shared.open(url)
        }
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
        subtitleLabel.text = progressView.isHidden ? "\(file.size.bitrateToHumanReadable)" : "\(file.downloaded.bitrateToHumanReadable) / \(file.size.bitrateToHumanReadable) (\(percent))"
        progressView.progress = file.progress
        fileImageView.image = .icon(forFileURL: viewModel.path)
        switchView.isOn = file.priority != .dontDownload
        switchView.onTintColor = file.priority.color
        shareButton.isHidden = file.progress < 1
        switchView.isHidden = !shareButton.isHidden
    }
}

private extension TorrentFilesFileListCell {
    class Delegates: DelegateObject<TorrentFilesFileListCell>, QLPreviewControllerDataSource {
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        @MainActor
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            parent.viewModel.path as NSURL
        }
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
