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
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .fontWeight(.semibold)
            HStack {
                HStack {
                    Text("Peers")
                    Text("\(viewModel.peers)")
                }
                Spacer()
                HStack {
                    Text("Seeds")
                    Text("\(viewModel.seeds)")
                }
                Spacer()
                HStack {
                    Text("Leechs")
                    Text("\(viewModel.leechs)")
                }
            }
            if let message = viewModel.message,
               !message.isEmpty
            {
                Text("Message: \(message)")
            }
        }
        .systemMinimumHeight()
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.accessories = [.multiselect(displayed: .whenEditing)]
    }
}

#Preview {
    let vm = TrackerCellViewModel()
    vm.title = "Top tracker"
    vm.peers = 390
    vm.leechs = 230
    vm.seeds = 5200

    vm.message = "Top tracker"
    return TrackerCellView(viewModel: vm)
        .frame(maxWidth: .infinity)
//        .border(Color.blue)
}
