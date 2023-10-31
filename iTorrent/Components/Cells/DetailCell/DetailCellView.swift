//
//  DetailCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import SwiftUI
import MvvmFoundation

struct DetailCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: DetailCellViewModel

    var body: some View {
        HStack {
            Text(viewModel.title)
                .fontWeight(.semibold)
            Spacer(minLength: 80)
            Text(viewModel.detail)
                .foregroundStyle(Color(.secondaryAccent))
                .multilineTextAlignment(.trailing)
        }
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = {
        return .init { cell, indexPath, itemIdentifier in
            cell.contentConfiguration = UIHostingConfiguration {
                Self(viewModel: itemIdentifier)
            }
        }
    }()
}

//#Preview {
//    DetailCellView()
//}
