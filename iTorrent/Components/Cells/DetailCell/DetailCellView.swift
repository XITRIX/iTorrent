//
//  DetailCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import MvvmFoundation
import SwiftUI

struct DetailCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: DetailCellViewModel

    var body: some View {
        let isHorizontal = viewModel.detail.count < 100

        if isHorizontal {
            HStack {
                Text(viewModel.title)
                    .fontWeight(viewModel.isBold ? .semibold : .regular)
                    .foregroundStyle(viewModel.isEnabled ? Color.primary : Color.secondary)
                Spacer(minLength: viewModel.spacer)
                Text(LocalizedStringKey(viewModel.detail))
                    .foregroundStyle(Color.accentColor)
                //                .foregroundStyle(Color.secondaryAccent)
                    .multilineTextAlignment(.trailing)
            }
            .systemMinimumHeight()
        } else {
            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .fontWeight(.semibold)
                Spacer()
                Text(LocalizedStringKey(viewModel.detail))
                    .foregroundStyle(Color.accentColor)
                //                .foregroundStyle(Color.secondaryAccent)
            }
            .padding(.vertical, 4)
            .systemMinimumHeight()
        }
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.isUserInteractionEnabled = itemIdentifier.isEnabled
        cell.accessories = itemIdentifier.selectAction == nil ? [] : [.disclosureIndicator(displayed: .always)]
    }
}

#Preview {
    DetailCellView(viewModel: .init(title: "Title", detail: "Detail"))
}

struct DynamicStack<Content: View>: View {
    var horizontalAlignment = HorizontalAlignment.center
    var verticalAlignment = VerticalAlignment.center
    var spacing: CGFloat?

    var isHorizontal: () -> Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        if isHorizontal() {
            HStack(
                alignment: verticalAlignment,
                spacing: spacing,
                content: content
            )
        } else {
            VStack(
                alignment: horizontalAlignment,
                spacing: spacing,
                content: content
            )
        }
    }
}
