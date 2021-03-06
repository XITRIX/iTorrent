//
//  TorrentLimitPicker.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.03.2021.
//  Copyright © 2021  XITRIX. All rights reserved.
//

import UIKit

class TorrentLimitPicker: PopupViewController {
    let data = [Int](-1 ... 10)
    var action: ((Int) -> ())!
    var dismissA: ((Int) -> ())?
    
    var picker: UIPickerView

    override func themeUpdate() {
        super.themeUpdate()
        picker.reloadAllComponents()
    }

    init(defaultValue: Int, dataSelected: ((Int) -> ())? = nil, dismissAction: ((Int) -> ())? = nil) {
        picker = UIPickerView()
        super.init(picker, contentHeight: 180)

        self.action = dataSelected
        self.dismissA = dismissAction

        picker.dataSource = self
        picker.delegate = self
        
        picker.selectRow(data.firstIndex(of: defaultValue) ?? 0, inComponent: 0, animated: true)
    }
    
    override func dismiss(animationOnly: Bool = false) {
        super.dismiss(animationOnly: animationOnly)
        dismissA?(data[picker.selectedRow(inComponent: 0)])
    }
    
    static func toString(_ num: Int) -> String {
        if num == -1 { return "Disabled".localized }
        return "\(num)"
    }
}

extension TorrentLimitPicker: UIPickerViewDataSource, UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        data.count
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        TorrentLimitPicker.toString(data[row])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action(data[row])
    }
}
