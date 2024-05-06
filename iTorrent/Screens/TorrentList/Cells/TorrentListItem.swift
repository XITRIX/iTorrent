//
//  TorrentListItem.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import LibTorrent
import MvvmFoundation
import SwiftUI

struct TorrentListItemView: MvvmSwiftUICellProtocol {
    typealias ViewModel = TorrentListItemViewModel

    @ObservedObject var viewModel: TorrentListItemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .foregroundStyle(.primary)
                .font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: 0) {
                Text(String(viewModel.progressText))
                Text(String(viewModel.statusText))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(.secondary)
            .font(.footnote)
            ProgressView(value: viewModel.progress)
        }
        .swipeActions {
            Button(role: .destructive) {
                viewModel.removeTorrent()
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
    }
}
