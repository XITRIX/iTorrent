//
//  TorrentListItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import SwiftUI

class TorrentListItemViewModel: BaseViewModelWith<TorrentHandle>, MvvmSelectableProtocol, ObservableObject, Identifiable {
    var torrentHandle: TorrentHandle!
    @Published var updater: Bool = false
    var selectAction: (() -> Void)?
    var id: Int { hashValue }

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model

        disposeBag.bind {
            torrentHandle.updatePublisher
                .sink { [unowned self] _ in
//                    withAnimation {
                        updater.toggle()
//                    }
                }
        }

        selectAction = { [unowned self] in
            navigate(to: TorrentDetailsViewModel.self, with: model, by: .detail(asRoot: true))
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(torrentHandle)
    }
}
