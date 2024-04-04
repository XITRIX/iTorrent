//
//  TorrentDetailProgressCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31/10/2023.
//

import MvvmFoundation
import SwiftUI

struct TorrentDetailProgressCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: TorrentDetailProgressCellViewModel

    var body: some View {
        HStack {
            Text(viewModel.title)
                .fontWeight(.semibold)
            Spacer(minLength: 24)
            VStack {
                ProgressView(value: viewModel.progress)
//                    .foregroundStyle(Color(PreferencesStorage.shared.tintColor))
                    .foregroundStyle(Color(.secondaryAccent))
                    .multilineTextAlignment(.trailing)
                SegmentedProgressView(progress: $viewModel.segmentedProgress)
                    .frame(height: 4)
                    .clipShape(Capsule())
            }
        }
        .systemMinimumHeight()
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
    }
}

#Preview {
    TorrentDetailProgressCellView(viewModel: .init(title: "Title", progress: 0.5, segmentedProgress: [0.5]))
}
