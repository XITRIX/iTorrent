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
            Spacer()
            Text(viewModel.value)
                .foregroundStyle(.tint)
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
