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
    @IBOutlet private var progressView: UISegmentedProgressView!
    @IBOutlet private var progressViewPlaceholder: UIView!
    @IBOutlet private var switchView: UISwitch!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var fileImageView: UIImageView!

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
        progressViewPlaceholder.isHidden = !viewModel.showProgress

        disposeBag.bind {
            viewModel.updatePublisher
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink
            { [weak self] _ in
                self?.reload()
            }
            viewModel.selected.sink { [unowned self] _ in
                if viewModel.file.progress >= 1 {
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

        let title = file.name
        let subtitle = !viewModel.showProgress ? "\(file.size.bitrateToHumanReadable)" : "\(file.downloaded.bitrateToHumanReadable) / \(file.size.bitrateToHumanReadable) (\(percent))"
        let progress = file.segmentedProgress
        let fileImage = UIImage.icon(forFileURL: viewModel.path)
        let switchIsOn = file.priority != .dontDownload
        let switchOnTintColor = file.priority.color
        let shareButtonHiden = file.progress < 1
        let switchHidden = !shareButtonHiden

        DispatchQueue.main.async { [self] in
            titleLabel.text = title
            subtitleLabel.text = subtitle
            progressView.progress = progress
            fileImageView.image = fileImage
            switchView.isOn = switchIsOn
            switchView.onTintColor = switchOnTintColor
            shareButton.isHidden = shareButtonHiden
            switchView.isHidden = switchHidden

            UIView.performWithoutAnimation {
                invalidateIntrinsicContentSize()
            }
        }
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
    var progress: Double {
        Double(downloaded) / Double(size)
    }

    var segmentedProgress: [Double] {
        let res = pieces.map { $0.doubleValue }
        if !res.isEmpty { return res }

        return [progress]
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
