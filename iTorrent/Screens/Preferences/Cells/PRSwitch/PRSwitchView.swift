//
//  PRSwitchView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import MvvmFoundation
import SwiftUI

struct PRSwitchView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: PRSwitchViewModel

    var body: some View {
        HStack {
            Toggle(viewModel.title, isOn: viewModel.value)
        }
    }

    static var registration: UICollectionView.CellRegistration<UICollectionViewListCell, PRSwitchViewModel> = .init { cell, indexPath, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
//        cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
    }
}

#Preview {
    PRSwitchView(viewModel: .init(with: .init(title: "Title", value: .constant(true))))
}
