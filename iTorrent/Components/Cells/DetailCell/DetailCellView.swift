//
//  DetailCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import MvvmFoundation
import SwiftUI

struct DetailCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: DetailCellViewModel

    var body: some View {
        HStack {
            Text(viewModel.title)
                .fontWeight(.semibold)
            Spacer(minLength: viewModel.spacer)
            Text(viewModel.detail)
                .foregroundStyle(Color.accentColor)
//                .foregroundStyle(Color.secondaryAccent)
                .multilineTextAlignment(.trailing)
        }
        .systemMinimumHeight()
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.accessories = itemIdentifier.selectAction == nil ? [] : [.disclosureIndicator(displayed: .always)]
    }
}

#Preview {
    DetailCellView(viewModel: .init(title: "Title", detail: "Detail"))
}
