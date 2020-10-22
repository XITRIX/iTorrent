//
//  TimeLimitPicker.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 13.02.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class TimeLimitPicker: PopupViewController {
    var action: ((Int) -> ())?
    var dismissA: ((Int) -> ())?
    var picker: UIPickerView!

    var size: [Int] = [0, 1, 2, 5, 10]

    @objc override func themeUpdate() {
        super.themeUpdate()
        picker.reloadAllComponents()
    }

    init(defaultValue: Int, dataSelected: ((Int) -> ())? = nil, dismissAction: ((Int) -> ())? = nil) {
        self.picker = UIPickerView()
        super.init(picker, contentHeight: 180)

        self.action = dataSelected
        self.dismissA = dismissAction

        picker.dataSource = self
        picker.delegate = self

        picker.selectRow(size.firstIndex(of: defaultValue) ?? 0, inComponent: 0, animated: true)
    }
    
    override func dismiss(animationOnly: Bool = false) {
        super.dismiss(animationOnly: animationOnly)
        dismissA?(size[picker.selectedRow(inComponent: 0)] * 60)
    }
}

extension TimeLimitPicker: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        size.count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let theme = Themes.current
        let titleFont: [NSAttributedString.Key: Any] = [.foregroundColor: theme.mainText]
        if component == 0, row == 0 {
            return NSAttributedString(string: NSLocalizedString("Disabled", comment: ""), attributes: titleFont)
        }
        return NSAttributedString(string: "\(size[row]) \(Localize.getTermination("minute", size[row]))", attributes: titleFont)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action?(size[row] * 60)
    }
}
