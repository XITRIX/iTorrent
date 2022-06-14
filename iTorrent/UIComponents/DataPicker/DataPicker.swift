//
//  DataPicker.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 31.05.2022.
//

import UIKit
import XTBottomSheet

protocol DataPickerDelegate: AnyObject {
    func dataChanged(from picker: DataPicker, at indexPath: IndexPath)
}

class DataPicker: UIViewController {
    @IBOutlet var dataPicker: UIPickerView!
    var data: [[String]]
    weak var delegate: DataPickerDelegate?

    init(with data: [[String]]) {
        self.data = data
        super.init(nibName: "DataPicker", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataPicker.dataSource = self
        dataPicker.delegate = self
    }

    func embedInBottomSheet() -> BottomSheetController {
        BottomSheetController(rootViewController: self, with: .init(withNavigationBar: false))
    }

    @IBAction func selfDismiss(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension DataPicker: BottomSheetControllerDelegate {
    var scrollMode: BottomSheetController.ScrollMode {
        .scrollView(nil)
    }
}

extension DataPicker: UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        data[component].count
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        data.count
    }
}

extension DataPicker: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        data[component][row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.dataChanged(from: self, at: .init(row: row, section: component))
    }
}
