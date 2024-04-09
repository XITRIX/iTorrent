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

        Task { await MemorySpaceManager.shared.update() }
        
        disposeBag.bind {
            MemorySpaceManager.shared.$storageCategories.sink { [unowned self] categories in
                let storage = categories.map { ($0.category.color, $0.percentage) }
                progressBarView.setProgress(storage)
                let res = categories.map { ($0.category.title, $0.category.color) }
                labels.labels = Array(res.prefix(4))
            }
        }
        freeSpaceText.text = "\(MemorySpaceManager.freeDiskSpace) \(%"preferences.storage.available")"
    }
}
