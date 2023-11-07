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
            let files = model.node.files
            let filesNeeded = files.filter { model.getPriority(for: $0) != .dontDownload }
            return TorrentFiles2DictionaryItemView(name: model.name, filesNeeded: filesNeeded.count, files: files.count) { [unowned self] in
                model.setPriority(.defaultPriority)
            } deselectAll: { [unowned self] in
                model.setPriority(.dontDownload)
            }
        }
    }
}

struct TorrentFiles2DictionaryItemView: View {
    var name: String
    var filesNeeded: Int
    var files: Int

    var selectAll: (() -> Void)?
    var deselectAll: (() -> Void)?

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
                Text("\(filesNeeded) \\ \(files) items")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            Spacer()
            Menu {
                Button("files.deselectAll", systemImage: "xmark.circle", role: .destructive) {
                    deselectAll?()
                }
                Button("files.selectAll", systemImage: "checkmark.circle") {
                    selectAll?()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .resizable()
                    .frame(width: 22, height: 22)
            }


        }
        .frame(minHeight: 54)
    }
}

#Preview {
    TorrentFiles2DictionaryItemView(name: "Dictionary", filesNeeded: 3, files: 12)
}
