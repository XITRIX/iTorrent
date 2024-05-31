//
//  PRColorPickerCell.swift
//  ReManga
//
//  Created by Даниил Виноградов on 01.06.2023.
//

import MvvmFoundation
import UIKit

class PRColorPickerCell<VM: PRColorPickerViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var colorsStack: UIStackView!
    @IBOutlet private var scrollView: UIScrollView!
    private let colors: [UIColor] = [
        .accent,
        .systemBlue,
        .systemIndigo,
        .systemPurple,
        .systemPink,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemMint,
        .systemTeal,
        .systemCyan
    ]
    private let colorViewSize: Double = 38
    private lazy var delegates = Delegates(parent: self)

    override func initSetup() {
        fillWithColors()
    }

    override func setup(with viewModel: VM) {}

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        scrollView.contentInset.left = layoutMargins.left
        scrollView.contentInset.right = layoutMargins.right
    }

    @IBAction func colorPicker(_ sender: UIControl) {
        let vc = CustomColorPickerViewController()
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

                switch color {
                case .accent:
                    UIApplication.shared.setAlternateIconName(nil)
                case .systemBlue:
                    UIApplication.shared.setAlternateIconName("AppIcon-Blue")
                case .systemIndigo:
                    UIApplication.shared.setAlternateIconName("AppIcon-Indigo")
                case .systemPurple:
                    UIApplication.shared.setAlternateIconName("AppIcon-Purple")
                case .systemPink:
                    UIApplication.shared.setAlternateIconName("AppIcon-Pink")
                case .systemRed:
                    UIApplication.shared.setAlternateIconName("AppIcon-Red")
                case .systemOrange:
                    UIApplication.shared.setAlternateIconName(nil)
                case .systemYellow:
                    UIApplication.shared.setAlternateIconName("AppIcon-Yellow")
                case .systemGreen:
                    UIApplication.shared.setAlternateIconName("AppIcon-Green")
                case .systemMint:
                    UIApplication.shared.setAlternateIconName("AppIcon-Mint")
                case .systemTeal:
                    UIApplication.shared.setAlternateIconName("AppIcon-Teal")
                case .systemCyan:
                    UIApplication.shared.setAlternateIconName("AppIcon-Cyan")
                default:
                    break
                }
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

private class CustomColorPickerViewController: UIColorPickerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

#if !os(visionOS)
        guard let sheet = sheetPresentationController else { return }
        sheet.prefersGrabberVisible = true

        sheet.detents = [.custom(resolver: { [unowned self] context in
            let height = preferredContentSize.height
            return min(height, context.maximumDetentValue)
        })]

        publisher(for: \.preferredContentSize).sink(receiveValue: { _ in
            sheet.animateChanges {
                sheet.invalidateDetents()
            }
        }).store(in: disposeBag)
#endif
    }

    private var disposeBag = DisposeBag()
}
