//
//  SpeedPicker.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class SpeedPicker : PopupView, Themed {
    var action: ((Int64)->())?
    var dismissA: ((Int64)->())?
    var picker: UIPickerView!
    
    var result : Int64 = 0
    
    var size : [[Int]] = {
        var mbSize : [Int] = []
        for i in 0 ... 8 {
            mbSize.append(i * 128)
        }
        
        var gbSize : [Int] = []
        for i in 0 ... 8 {
            gbSize.append(i)
        }
        
        var res = [[Int]]()
        res.append(mbSize)
        res.append(gbSize)
        return res
    }()
    var sizes = ["KB/S", "MB/S"]
    
    @objc func themeUpdate() {
        let theme = Themes.current
        toolbar.tintColor = theme.tintColor
        fxView.effect = UIBlurEffect(style: theme.blurEffect)
        if #available(iOS 11, *) {} else {
            fxView.backgroundColor = theme.backgroundMain
        }
        picker.reloadAllComponents()
    }
    
    init(defaultValue: Int64, dataSelected: ((Int64)->())? = nil, dismissAction: ((Int64)->())? = nil) {
        picker = UIPickerView()
        super.init(contentView: picker, contentHeight: 180)
        
        self.action = dataSelected
        self.dismissA = dismissAction
        self.result = defaultValue
        
        picker.dataSource = self
        picker.delegate = self
        
        let def = defaultValue / 1024
        if def > 1024 {
            picker.selectRow(1, inComponent: 1, animated: true)
            picker.selectRow(Int(def/1024), inComponent: 0, animated: true)
        } else {
            picker.selectRow(0, inComponent: 1, animated: true)
            picker.selectRow(Int(def/128), inComponent: 0, animated: true)
        }
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    override func dismiss() {
        super.dismiss()
        dismissA?(result)
    }
}

extension SpeedPicker : UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            if (pickerView.numberOfComponents > 1 && pickerView.numberOfRows(inComponent: 1) > 1 && pickerView.selectedRow(inComponent: 1) == 1) {
                return size[1].count
            }
            return size[0].count
        }
        return sizes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let theme = Themes.current
        let titleFont:[NSAttributedString.Key : Any] = [ .foregroundColor : theme.mainText ]
        if (component == 0 && row == 0) {
            return NSAttributedString(string: NSLocalizedString("Unlimited", comment: ""), attributes: titleFont)
        }
        if (component == 0) {
            if (pickerView.numberOfComponents > 1 && pickerView.numberOfRows(inComponent: 1) > 1 && pickerView.selectedRow(inComponent: 1) == 1) {
                return NSAttributedString(string: String(size[1][row]), attributes: titleFont)
            }
            return NSAttributedString(string: String(size[0][row]), attributes: titleFont)
        }
        return NSAttributedString(string: sizes[row], attributes: titleFont)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (component == 1) {
            pickerView.reloadComponent(0)
        }
        let cmp0 = pickerView.selectedRow(inComponent: 0)
        let cmp1 = pickerView.selectedRow(inComponent: 1)
        if (cmp1 == 0) {
            result = Int64(size[cmp1][cmp0]) * 1024
        } else {
            result = Int64(size[cmp1][cmp0]) * 1048576
        }
        action?(result)
    }
}
