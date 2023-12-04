//
//  TrackerCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import SwiftUI
import MvvmFoundation

struct TrackerCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: TrackerCellViewModel

    var body: some View {
        HStack {
            Text(viewModel.title)
                .fontWeight(.semibold)
        }
        #if os(visionOS)
        .frame(minHeight: 44)
        #endif
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.accessories = [.multiselect(displayed: .whenEditing)]
    }
}

#Preview {
    TrackerCellView(viewModel: .init())
}
