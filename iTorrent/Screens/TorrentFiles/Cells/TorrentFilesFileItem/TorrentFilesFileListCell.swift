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
    private let reloadQueue = DispatchQueue(
        label: "com.xitrix.iTorrent.torrent-file-cell-reload",
        qos: .userInitiated
    )

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var progressView: UISegmentedProgressView!
    @IBOutlet private var progressViewPlaceholder: UIView!
    @IBOutlet private var switchView: UISwitchWithMenu!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var fileImageView: UIImageView!

    override func initSetup() {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        titleLabel.font = fontMetrics.scaledFont(for: font)

        switchView.addTarget(self, action: #selector(switcher), for: .valueChanged)
        separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true

        shareButton.contentHorizontalAlignment = .trailing
        shareButton.showsMenuAsPrimaryAction = true
        shareButton.menu = UIMenu(children: [
            UIAction(title: %"file.open") { [unowned self] _ in
                guard let vm = viewModel as? TorrentFilesFileItemViewModel else { return }
                vm.previewAction?()
            },
            UIAction(title: %"file.share", image: .init(systemName: "square.and.arrow.up")) { [unowned self] _ in
                shareAction()
            },
            UIAction(title: %"file.showInFiles", image: .init(systemName: "folder")) { [unowned self] _ in
                showInFiles()
            }
        ])

        switchView.menu = .makeForChangePriority { [unowned self] priority in
            viewModel.setPriority(priority)
        }

        accessories = [.multiselect(displayed: .whenEditing)]
    }

    override func setup(with viewModel: VM) {
        setViewModel(viewModel)

        progressView.isHidden = !viewModel.showProgress
        progressViewPlaceholder.isHidden = !viewModel.showProgress
        fileImageView.image = UIImage.icon(forFileURL: viewModel.path)

        disposeBag.bind {
            viewModel.updatePublisher
                .map { _ in () }
                .prepend(())
                .receive(on: reloadQueue)
                .map { [viewModel] _ in
                    TorrentFileCellReloadData(
                        file: viewModel.file,
                        showProgress: viewModel.showProgress
                    )
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] data in
                    self?.reload(with: data)
                }
            viewModel.selected.sink { [unowned self] _ in
                switchView.setOn(!switchView.isOn, animated: true)
                switcher(switchView)
            }
        }
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

private struct TorrentFileCellReloadData {
    private static let maximumProgressSegmentCount = 512

    let title: String
    let subtitle: String
    let progress: [Double]
    let priority: FileEntry.Priority
    let isShareButtonHidden: Bool
    let isSwitchHidden: Bool

    init(file: FileEntry, showProgress: Bool) {
        let fileProgress = file.progress
        let percent = "\(String(format: "%.2f", fileProgress * 100))%"

        title = file.name
        subtitle = showProgress
            ? "\(file.downloaded.bitrateToHumanReadable) / \(file.size.bitrateToHumanReadable) (\(percent))"
            : "\(file.size.bitrateToHumanReadable)"
        progress = showProgress
            ? file.segmentedProgress(maximumSegmentCount: Self.maximumProgressSegmentCount)
            : [fileProgress]
        priority = file.priority
        isShareButtonHidden = fileProgress < 1
        isSwitchHidden = !isShareButtonHidden
    }
}

private extension TorrentFilesFileListCell {
    func reload(with data: TorrentFileCellReloadData) {
        let isSwitchOn = data.priority != .dontDownload

        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
        progressView.progress = data.progress
        if switchView.isOn != isSwitchOn {
            switchView.isOn = isSwitchOn
        }
        switchView.onTintColor = data.priority.color
        shareButton.isHidden = data.isShareButtonHidden
        switchView.isHidden = data.isSwitchHidden

        UIView.performWithoutAnimation {
            invalidateIntrinsicContentSize()
        }
    }
}

extension FileEntry {
    var segmentedProgress: [Double] {
        segmentedProgress(maximumSegmentCount: .max)
    }

    func segmentedProgress(maximumSegmentCount: Int) -> [Double] {
        guard !pieces.isEmpty else { return [progress] }

        let segmentCount = min(pieces.count, max(1, maximumSegmentCount))
        guard segmentCount < pieces.count else {
            return pieces.map(\.doubleValue)
        }

        return (0 ..< segmentCount).map { segmentIndex in
            let startIndex = segmentIndex * pieces.count / segmentCount
            let endIndex = (segmentIndex + 1) * pieces.count / segmentCount
            let completed = pieces[startIndex ..< endIndex].reduce(0.0) {
                $0 + $1.doubleValue
            }
            return completed / Double(endIndex - startIndex)
        }
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
