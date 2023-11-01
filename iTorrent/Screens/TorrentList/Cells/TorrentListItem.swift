//
//  TorrentListItem.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import SwiftUI
import MvvmFoundation
import LibTorrent

struct TorrentListItemView: MvvmSwiftUICellProtocol {
    typealias ViewModel = TorrentListItemViewModel

    @ObservedObject var viewModel: TorrentListItemViewModel

    var body: some View {
        VStack(alignment: .leading, content: {
            let percent = "\(String(format: "%.2f", viewModel.torrentHandle.progress * 100))%"
            Text(viewModel.torrentHandle.name)
                .foregroundStyle(.primary)
                .font(.subheadline.weight(.semibold))
            Text("\(viewModel.torrentHandle.totalWantedDone.bitrateToHumanReadable) of \(viewModel.torrentHandle.totalWanted.bitrateToHumanReadable) (\(percent))")
                .foregroundStyle(.secondary)
                .font(.footnote)
            Text("\(viewModel.torrentHandle.friendlyState.name)")
                .foregroundStyle(.secondary)
                .font(.footnote)
            ProgressView(value: viewModel.torrentHandle.progress)
        })
        .swipeActions {
            Button(role: .destructive) {
                TorrentService.shared.removeTorrent(by: viewModel.torrentHandle.infoHashes)
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = {
        return .init { cell, indexPath, itemIdentifier in
            cell.contentConfiguration = UIHostingConfiguration {
                Self(viewModel: itemIdentifier)
            }
            cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
        }
    }()
}
