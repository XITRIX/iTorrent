//
//  PRColorPickerCell.swift
//  ReManga
//
//  Created by Даниил Виноградов on 01.06.2023.
//

import UIKit
import MvvmFoundation

class PRColorPickerCell<VM: PRColorPickerViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var colorsStack: UIStackView!
    @IBOutlet private var scrollView: UIScrollView!
    private let colors: [UIColor] = [.accent, .systemBlue, .systemPurple, .systemPink, .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemCyan]
    private let colorViewSize: Double = 38
    private lazy var delegates = Delegates(parent: self)

    override func initSetup() {
        fillWithColors()
    }

    override func setup(with viewModel: VM) {

    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        scrollView.contentInset.left = layoutMargins.left
        scrollView.contentInset.right = layoutMargins.right
    }

    @IBAction func colorPicker(_ sender: UIControl) {
        let vc = UIColorPickerViewController()
        vc.selectedColor = PreferencesStorage.shared.tintColor
        vc.delegate = delegates
        viewController?.present(vc, animated: true)
    }
}

private extension PRColorPickerCell {
    func fillWithColors() {
        for color in colors {
            let view = makeColorView(color)
            view.addAction(.init { _ in
                PreferencesStorage.shared.tintColor = color
            }, for: .touchUpInside)
            colorsStack.addArrangedSubview(view)
        }

        for view in colorsStack.arrangedSubviews {
            view.layer.cornerRadius = colorViewSize / 2
            view.layer.borderWidth = 1
            view.borderColor = .label
        }
    }

    func makeColorView(_ color: UIColor) -> UIControl {
        let view = UIControl()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = color

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: colorViewSize),
            view.heightAnchor.constraint(equalToConstant: colorViewSize)
        ])

        return view
    }
}

extension PRColorPickerCell {
    class Delegates: DelegateObject<PRColorPickerCell>, UIColorPickerViewControllerDelegate {
        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            PreferencesStorage.shared.tintColor = color
        }
    }
}
