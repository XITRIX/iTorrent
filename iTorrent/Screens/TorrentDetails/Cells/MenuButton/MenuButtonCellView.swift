//
//  MenuButtonCellView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 03.04.2026.
//

import SwiftUI
import UIKit
import MvvmFoundation

struct MenuButtonCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: MenuButtonCellViewModel

    var body: some View {
        HStack {
            Text(viewModel.title)
                .fontWeight(viewModel.isBold ? .semibold : .regular)
            Spacer()
            UIText(viewModel.value)
            MenuButton(menu: viewModel.menu, viewModel: viewModel)
        }
        .systemMinimumHeight()
    }

    static var registration: UICollectionView.CellRegistration<MvvmCollectionViewListCell<MenuButtonCellViewModel>, MenuButtonCellViewModel> = .init { cell, indexPath, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }

        bind(in: cell.disposeBag) {
//            itemIdentifier.$menu.sink { menu in
//                cell.accessories = accessories
//            }
        }
    }
}

struct UIText: UIViewRepresentable {
    let value: NSAttributedString?

    init(_ value: NSAttributedString?) {
        self.value = value
    }

    func makeUIView(context: Context) -> UILabel {
        let view = UILabel()
        view.textColor = .tintColor
        return view
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = value
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        uiView.layoutIfNeeded()
        return uiView.intrinsicContentSize
    }
}

struct MenuButton: UIViewRepresentable {
    let menu: UIMenu
    @ObservedObject var viewModel: MenuButtonCellViewModel

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton()
        button.showsMenuAsPrimaryAction = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setShowsMenuFromSourceIfAvailable(false)
        viewModel.selectAction = {
            viewModel.dismissSelection?()

            if #available(iOS 17.4, *) {
                button.performPrimaryAction()
            } else {
                button.performMenuAction()
            }
        }
        button.configuration = .plain()
        button.configuration?.imagePlacement = .trailing

        let config = UIImage.SymbolConfiguration(textStyle: .body)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))
            .applying(UIImage.SymbolConfiguration.init(scale: .small))
        let image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: config)
        button.configuration?.image = image
        button.configuration?.imagePadding = 8
        button.configuration?.contentInsets = .zero
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.menu = menu
//        uiView.configuration?.attributedTitle = value
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIButton, context: Context) -> CGSize? {
        uiView.layoutIfNeeded()
        return uiView.intrinsicContentSize
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var disposeBag = DisposeBag()
    }
}

extension UIButton {
    @discardableResult
    func performMenuAction() -> Bool {
        // _presentMenuAtLocation:
        let selector = NSSelectorFromBase64String("X3ByZXNlbnRNZW51QXRMb2NhdGlvbjo=")

        for interaction in interactions where interaction.responds(to: selector) {
            let pointValue = NSValue(cgPoint: CGPoint(x: bounds.midX, y: bounds.midY))
            _ = interaction.perform(selector, with: pointValue)
            return true
        }

        return false
    }
}

extension UIButton {
    func setShowsMenuFromSourceIfAvailable(_ enabled: Bool) {
        // setShowsMenuFromSource:
        let setter = NSSelectorFromBase64String("c2V0U2hvd3NNZW51RnJvbVNvdXJjZTo=")
        guard responds(to: setter) else { return }

        // showsMenuFromSource
        setValue(enabled, forKey: String(base64: "c2hvd3NNZW51RnJvbVNvdXJjZQ=="))
    }
}
