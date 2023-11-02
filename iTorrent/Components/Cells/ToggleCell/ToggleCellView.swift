//
//  ToggleCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/11/2023.
//

import MvvmFoundation
import SwiftUI

struct ToggleCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: ToggleCellViewModel

    var body: some View {
        HStack {
//            Spacer(minLength: viewModel.spacer)
            Toggle(isOn: $viewModel.isOn) {
                Text(viewModel.title)
                    .fontWeight(.semibold)
            }
        }
        #if os(visionOS)
        .frame(minHeight: 44)
        #endif
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.accessories = itemIdentifier.selectAction == nil ? [] : [.disclosureIndicator(displayed: .always)]
    }
}

#Preview {
    ToggleCellView(viewModel: .init(title: "Title", isOn: false))
}
