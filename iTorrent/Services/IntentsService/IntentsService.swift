//
//  IntentsService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 30.06.2024.
//

import MvvmFoundation
import Foundation

actor IntentsService {
    init() {
        disposeBag.bind {
            NotificationCenter.default.publisher(for: .pauseTorrent).sink { notification in
                guard let hash = notification.object as? String,
                      let torrentHandle = TorrentService.shared.modernHandle(forHex: hash)
                else { return }

                Task {
                    await torrentHandle.pause()
                }
            }
        }
    }

    private let disposeBag = DisposeBag()
}
