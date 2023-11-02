//
//  TorrentFilesItemView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01/11/2023.
//

import MvvmFoundation
import SwiftUI
import LibTorrent

struct TorrentFilesItemView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: TorrentFilesItemViewModel

    var body: some View {
        VStack(alignment: .leading) {
            let percent = "\(String(format: "%.2f", viewModel.file.progress * 100))%"
            Text(viewModel.file.name)
                .foregroundStyle(.primary)
                .font(.subheadline.weight(.semibold))
            Text("\(viewModel.file.downloaded.bitrateToHumanReadable) / \(viewModel.file.size.bitrateToHumanReadable) (\(percent))")
            .foregroundStyle(.secondary)
            .font(.footnote)
            ProgressView(value: viewModel.file.progress)
        }
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, TorrentFilesItemViewModel> = {
        return .init { cell, indexPath, itemIdentifier in
            cell.contentConfiguration = UIHostingConfiguration {
                Self(viewModel: itemIdentifier)
            }
            cell.accessories = [.multiselect(displayed: .whenEditing)]
        }
    }()
}

private extension FileEntry {
    var progress: Double {
        Double(downloaded) / Double(size)
    }
}

#Preview {
    TorrentFilesItemView(viewModel: .init(with: .init()))
}
