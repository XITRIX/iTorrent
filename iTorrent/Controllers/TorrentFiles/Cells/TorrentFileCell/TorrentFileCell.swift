//
//  TorrentFileCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import MVVMFoundation
import ReactiveKit
import TorrentKit
import UIKit

class TorrentFileCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var sizeLabel: UILabel!
    @IBOutlet private var switchView: UISwitchWithMenu!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var progressView: SegmentedProgressView!

    var menu: UIMenu? {
        get { switchView.menu }
        set {
            switchView.menu = newValue
            switchView.isContextMenuInteractionEnabled = newValue != nil
        }
    }

    var valueChanged: SafeSignal<FileEntry.Priority> { switchView.reactive.controlEvents(.valueChanged).map { [unowned self] _ in switchView.isOn ? .defaultPriority : .dontDownload } }

    func setup(with model: FileEntity) {
        reuseBag.dispose()

        titleLabel.text = model.name
        sizeLabel.text = "\(Utils.Size.getSizeText(size: UInt(model.size)))"
        switchView.setOn(model.priority != .dontDownload, animated: false)
        progressView.isHidden = model.prototype

        bind(in: reuseBag) {
            model.$priority.bidirectionalMap(
                to: { $0 != .dontDownload },
                from: {
                    let current: FileEntry.Priority = model.priority == .dontDownload ? .defaultPriority : model.priority
                    return $0 ? current : .dontDownload
                }
            ) <=> switchView.reactive.isOnAnimated
            model.$priority.map { [unowned self] in color(for: $0) } => switchView.reactive.onTintColor
            model.$pieces.map { $0.map { Float($0 ? 1 : 0) } } => progressView
            model.$progress.observeNext { [unowned self] value in
                switchView.isHidden = value == 1
                shareButton.isHidden = value < 1
            }
        }

        if model.prototype {
            sizeLabel.text = "\(Utils.Size.getSizeText(size: UInt(model.size)))"
        } else {
            (model.$downloaded.map { "\(Utils.Size.getSizeText(size: UInt($0))) / \(Utils.Size.getSizeText(size: UInt(model.size))) (\(String(format: "%0.2f%%", model.progress * 100)))" }
                => sizeLabel).dispose(in: reuseBag)
        }
    }

    func triggerSwitch() {
        guard !switchView.isHidden
        else { return }

        switchView.setOn(!switchView.isOn, animated: true)
        switchView.sendActions(for: .valueChanged)
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    private func color(for priority: FileEntry.Priority) -> UIColor? {
        switch priority {
        case .dontDownload:
            return .gray
        case .lowPriority:
            return .systemRed
        case .defaultPriority:
            return nil
        case .topPriority:
            return .systemBlue
        @unknown default:
            fatalError()
        }
    }
}
