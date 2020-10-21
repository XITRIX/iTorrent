//
//  DatasetPicker.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class DatasetPicker: PopupView {
    var data: [[String]]!
    var action: ((String) -> ())!

    override func themeUpdate() { }

    init(data: [[String]], dataSelected: @escaping (String) -> ()) {
        let picker = UIPickerView()
        super.init(contentView: picker, contentHeight: 180)

        self.data = data
        self.action = dataSelected

        picker.dataSource = self
        picker.delegate = self

        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setupView() {
        themeUpdate()
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
