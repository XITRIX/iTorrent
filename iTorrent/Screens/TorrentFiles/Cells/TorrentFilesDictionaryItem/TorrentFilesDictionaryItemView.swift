//
//  TorrentFilesDictionaryItemView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import MvvmFoundation
import SwiftUI

class TorrentFilesDictionaryItemViewCell<VM: DictionaryItemViewModelProtocol>: UICollectionViewListCell {
    var model: VM!
    var disposeBag = DisposeBag()

    func prepare(with model: VM) {
        self.model = model

        accessories = [.disclosureIndicator()]
        reload()

        disposeBag = DisposeBag()
        disposeBag.bind {
            model.updatePublisher.sink { [unowned self] _ in
                reload()
            }
        }
    }

    func reload() {
        contentConfiguration = UIHostingConfiguration {
            TorrentFiles2DictionaryItemView(name: model.name, files: model.node.storage.keys.count)
        }
    }
}

struct TorrentFiles2DictionaryItemView: View {
    var name: String
    var files: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(.folder)
                .resizable()
                .frame(width: 44, height: 44)
            VStack(alignment: .leading) {
                Text(name)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .font(.subheadline.weight(.semibold))
                Text("\(files) items")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .frame(minHeight: 54)
    }
}

#Preview {
    TorrentFiles2DictionaryItemView(name: "Dictionary", files: 2)
}
