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
            ProgressView(value: viewModel.progress)
                .foregroundStyle(Color(.secondaryAccent))
                .multilineTextAlignment(.trailing)
        }
        #if os(visionOS)
        .frame(minHeight: 44)
        #endif
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
    }
}

#Preview {
    TorrentDetailProgressCellView(viewModel: .init(title: "Title", progress: 0.5))
}
