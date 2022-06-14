//
//  SpeedPicker.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 31.05.2022.
//

import Foundation

class SpeedPicker: DataPicker {
    private var selectedSpeed: Int = 0
    private var selectedSpeedGroup: Int = 0
    private let callback: (UInt)->()

    override var data: [[String]] {
        get {
            let speeds = Utils.Dataset.sizes[selectedSpeedGroup].titles.map { size -> String in
                guard size != 0 else { return "Unlimited" }
                return "\(size)"
            }
            let texts = Utils.Dataset.sizes.map { $0.name }
            return [speeds, texts]
        }
        set {}
    }

    init(callback: @escaping (UInt)->()) {
        self.callback = callback
        super.init(with: [[]])
        delegate = self
    }

    private func notifyChange() {
        let group = Utils.Dataset.sizes[selectedSpeedGroup]
        callback(group.titles[selectedSpeed] * group.multiplier)
    }
}

extension SpeedPicker: DataPickerDelegate {
    func dataChanged(from picker: DataPicker, at indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            selectedSpeed = indexPath.row
            notifyChange()
        case 1:
            selectedSpeedGroup = indexPath.row
            dataPicker.reloadComponent(0)
            notifyChange()
        default: break
        }
    }
}
