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
            return TorrentFiles2DictionaryItemView(name: model.name, filesNeeded: filesNeeded.count, files: files.count, viewModel: model)
        }
    }
}

struct TorrentFiles2DictionaryItemView: View {
    var name: String
    var filesNeeded: Int
    var files: Int
    var viewModel: any DictionaryItemViewModelProtocol

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
            Menu("", systemImage: "ellipsis.circle") {
                Button("Deselect All", systemImage: "xmark.circle", role: .destructive) {
                    viewModel.setPriority(.dontDownload)
                }
                Button("Select All", systemImage: "checkmark.circle") {
                    viewModel.setPriority(.defaultPriority)
                }
            }

        }
        .frame(minHeight: 54)
    }
}

//#Preview {
//    TorrentFiles2DictionaryItemView(name: "Dictionary", files: 2, viewModel: <#DictionaryItemViewModelProtocol#>)
//}
