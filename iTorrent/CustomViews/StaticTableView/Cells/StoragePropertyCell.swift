//
//  StoragePropertyCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class StoragePropertyCell: ThemedUITableViewCell, PreferenceCellProtocol {
    @IBOutlet var progressBarView: ColoredProgressBarView!
    @IBOutlet var freeSpaceText: ThemedUILabel!
    @IBOutlet var labels: PortionBarLabels!
    
    static let id = "StoragePropertyCell"
    static let nib = UINib(nibName: id, bundle: nil)
    static let name = id
    
    override func themeUpdate() {
        super.themeUpdate()
        
        updateBarData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        progressBarView.layer.cornerRadius = 4
        updateBarData()
        
        MemorySpaceManager.shared.calculateDetailedSections { [weak self] _ in
            self?.updateBarData()
        }
        
        freeSpaceText.text = "\(MemorySpaceManager.freeDiskSpace) Available"
    }
    
    func updateBarData() {
        if let progressBarView = progressBarView,
            let labels = labels {
            let storage = MemorySpaceManager.shared.storageCategories.map { ($0.category.color, $0.percentage) }
            progressBarView.setProgress(storage)
            var res = MemorySpaceManager.shared.storageCategories.map { ($0.category.title, $0.category.color) }
            res.removeLast()
            labels.labels = res
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setModel(_ model: CellModelProtocol) {
        guard model is Model else {
            return
        }
    }
    
    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?
    }
}
