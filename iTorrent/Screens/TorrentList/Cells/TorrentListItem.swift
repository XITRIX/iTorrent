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
            Text(viewModel.torrentHandle.name)
                .foregroundStyle(.primary)
            Text("\(String(format: "%.2f", viewModel.torrentHandle.progress * 100))%")
                .foregroundStyle(.secondary)
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
            cell.accessories = [.disclosureIndicator()]
        }
    }()
}
