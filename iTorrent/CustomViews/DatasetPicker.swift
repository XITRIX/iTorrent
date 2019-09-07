//
//  DatasetPicker.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class DatasetPicker : PopupView, Themed {
    var data : [[String]]! //= ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"]
    var action : ((String)->())!
    
    func themeUpdate() {
        toolbar.tintColor = Themes.current().tintColor
    }
    
    init(data : [[String]], dataSelected: @escaping (String)->()) {
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

extension DatasetPicker : UIPickerViewDataSource, UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data[component].count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[component][row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action(data[component][row])
    }
}
