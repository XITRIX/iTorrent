//
//  DatasetPicker.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class DatasetPicker: PopupViewController {
    var data: [[String]]!
    var action: ((String) -> ())!
    
    var picker: UIPickerView

    override func themeUpdate() {
        super.themeUpdate()
        picker.reloadAllComponents()
    }

    init(data: [[String]], dataSelected: @escaping (String) -> ()) {
        picker = UIPickerView()
        super.init(picker, contentHeight: 180)

        self.data = data
        self.action = dataSelected

        picker.dataSource = self
        picker.delegate = self
    }
}

extension DatasetPicker: UIPickerViewDataSource, UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data[component].count
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        data.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        data[component][row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action(data[component][row])
    }
}
