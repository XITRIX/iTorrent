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
            let percent = "\(String(format: "%.2f", viewModel.torrentHandle.progress * 100))%"
            Text(viewModel.torrentHandle.name)
                .foregroundStyle(.primary)
                .font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(viewModel.torrentHandle.totalWantedDone.bitrateToHumanReadable) of \(viewModel.torrentHandle.totalWanted.bitrateToHumanReadable) (\(percent))")
                Text("\(viewModel.torrentHandle.friendlyState.name)")
            }
            .foregroundStyle(.secondary)
            .font(.footnote)
            ProgressView(value: viewModel.torrentHandle.progress)
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
