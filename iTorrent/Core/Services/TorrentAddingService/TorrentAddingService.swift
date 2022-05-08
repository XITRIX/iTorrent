//
//  TorrentAddingService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.05.2022.
//

import UIKit
import MVVMFoundation
import TorrentKit

class TorrentAddingService {
    enum Context {
        case VM(MvvmViewModel)
        case View(UIViewController)
    }

    private var context: Context?

//    func setContext(_ context: Context) {
//        self.context = context
//    }

    func addTorrent(_ torrent: Downloadable, from context: Context) {
        self.context = context

        switch torrent {
        case let file as TorrentFile:
            present(with: file)
        case let magnet as MagnetURI:
            if let file = MVVM.resolve(type: TorrentManager.self).torrents.first(where: { $0.key == torrent.infoHash }) {
                alert(for: file.value.name)
                return
            }
            MVVM.resolve(type: TorrentManager.self).addTorrent(magnet)
        default: break
        }
    }

    private func present(with torrent: TorrentFile) {
        if let file = MVVM.resolve(type: TorrentManager.self).torrents.first(where: { $0.key == torrent.infoHash }) {
            alert(for: file.value.name)
            return
        }

        switch context {
        case .VM(let vm):
            vm.navigate(to: TorrentAddingViewModel.self, prepare: .init(file: torrent), with: .modal(wrapInNavigation: true))
        case .View(let view):
            let vc = TorrentAddingViewModel.resolveView(with: .init(file: torrent))
            let nvc = UINavigationController.safeResolve()
            nvc.viewControllers = [vc]
            view.present(nvc, animated: true)
        case .none:
            break
        }
    }

    private func alert(for title: String) {
        let alert = UIAlertController(title: "Torrent already exists in download queue", message: title, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))

        switch context {
        case .VM(let vm):
            vm.attachedView.present(alert, animated: true)
        case .View(let view):
            view.present(alert, animated: true)
        case .none:
            break
        }
    }
}
