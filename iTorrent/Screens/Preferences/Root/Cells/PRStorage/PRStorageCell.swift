//
//  PRStorageCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/04/2024.
//

import UIKit
import MvvmFoundation

class PRStorageCell<VM: PRStorageViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var progressBarView: ColoredProgressBarView!
    @IBOutlet private var freeSpaceText: UILabel!
    @IBOutlet private var labels: PortionBarLabels!

    override func setup(with viewModel: VM) {
        progressBarView.layer.cornerRadius = 6
        progressBarView.layer.cornerCurve = .continuous
        updateBarData()

        MemorySpaceManager.shared.calculateDetailedSections { [weak self] _ in
            self?.updateBarData()
        }

        freeSpaceText.text = "\(MemorySpaceManager.freeDiskSpace) \(%"preferences.storage.available")"
    }

    func updateBarData() {
        if let progressBarView = progressBarView,
            let labels = labels {
            let storage = MemorySpaceManager.shared.storageCategories.map { ($0.category.color, $0.percentage) }
            progressBarView.setProgress(storage)
            var res = MemorySpaceManager.shared.storageCategories.map { ($0.category.title, $0.category.color) }
            if res.count > 4 {
                res.removeLast()
            }
            labels.labels = res
        }
    }
}
