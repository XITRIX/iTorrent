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

    static var registration: UICollectionView.CellRegistration<UICollectionViewListCell, PRButtonViewModel> = .init { cell, indexPath, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
//        cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
    }
}

#Preview {
    PRButtonView(viewModel: .init())
}
