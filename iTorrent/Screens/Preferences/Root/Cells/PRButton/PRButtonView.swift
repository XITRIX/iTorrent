//
//  PRButtonView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import SwiftUI
import MvvmFoundation

struct PRButtonView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: PRButtonViewModel

    var body: some View {
        HStack {
            Text(viewModel.title)
                .fontWeight(viewModel.isBold ? .semibold : .regular)
                .foregroundStyle(viewModel.tintedTitle ? Color.accentColor : Color.primary)
            Spacer()
            Text(viewModel.value)
                .foregroundStyle(viewModel.tinted ? Color.accentColor : Color.secondary)
                .lineLimit(viewModel.singleLine ? 1 : nil)
                .multilineTextAlignment(.trailing)
        }
        .systemMinimumHeight()
        .swipeActions {
            if let removeAction = viewModel.removeAction {
                Button(role: .destructive) {
                    removeAction()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    static var registration: UICollectionView.CellRegistration<MvvmCollectionViewListCell<PRButtonViewModel>, PRButtonViewModel> = .init { cell, indexPath, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }

        bind(in: cell.disposeBag) {
            itemIdentifier.$accessories.sink { accessories in
                cell.accessories = accessories
            }
        }
    }
}

#Preview {
    PRButtonView(viewModel: .init())
}
