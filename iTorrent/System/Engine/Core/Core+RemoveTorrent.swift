//
//  Core+RemoveTorrent.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

extension Core {
    func removeTorrentsUI(hashes: [String], sender: Any, direction: UIPopoverArrowDirection = .any, completionAction: (()->())? = nil) {
        let torrents = hashes.compactMap({Core.shared.torrents[$0]})
        
        var title: String?
        var message: String?
        
        let isMagnet = torrents.count == 1 && !torrents[0].hasMetadata
        if isMagnet {
            title = nil
            message = Localize.get("Are you sure to remove this magnet torrent?")
        } else {
            title = "\(Localize.get("Are you sure to remove"))"
            title! += torrents.count > 1 ? " \(torrents.count) \(Localize.get("torrents"))?" : "?"
            message = torrents.map({$0.title}).joined(separator: "\n")
        }

        let removeController = ThemedUIAlertController(title: title,
                                                       message: message,
                                                       preferredStyle: .actionSheet)
        
        let removeAll = UIAlertAction(title: NSLocalizedString("Yes and remove data", comment: ""), style: .destructive) { _ in
            for torrent in torrents {
                self.removeTorrent(hash: torrent.hash, removeData: true, notify: false)
            }
            completionAction?()
            NotificationCenter.default.post(name: .torrentRemoved, object: torrents.map({$0.hash}))
        }
        let removeTorrent = UIAlertAction(title: NSLocalizedString("Yes but keep data", comment: ""), style: .default) { _ in
            for torrent in torrents {
                self.removeTorrent(hash: torrent.hash, removeData: false, notify: false)
            }
            completionAction?()
            NotificationCenter.default.post(name: .torrentRemoved, object: torrents.map({$0.hash}))
        }
        let removeMagnet = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { _ in
            self.removeTorrent(hash: torrents[0].hash, removeData: false, notify: false)
            completionAction?()
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

        if isMagnet {
            removeController.addAction(removeMagnet)
        } else {
            removeController.addAction(removeAll)
            removeController.addAction(removeTorrent)
        }
        removeController.addAction(cancel)

        if removeController.popoverPresentationController != nil {
            if let bb = sender as? UIBarButtonItem {
                removeController.popoverPresentationController?.barButtonItem = bb
            } else if let view = sender as? UIView {
                removeController.popoverPresentationController?.sourceView = view
                removeController.popoverPresentationController?.sourceRect = view.bounds
            }
            removeController.popoverPresentationController?.permittedArrowDirections = direction
        }

        Utils.topViewController?.present(removeController, animated: true)
    }

    func removeTorrent(hash: String, removeData: Bool = false, notify: Bool = true) {
        guard let torrent = torrents[hash] else { return }
        TorrentSdk.removeTorrent(hash: torrent.hash, withFiles: removeData)

        if torrent.hasMetadata {
            removeTorrentFile(hash: torrent.hash)

            if removeData {
                do {
                    try FileManager.default.removeItem(atPath: Core.rootFolder + "/" + torrent.title)
                } catch {
                    print("MainController: removeTorrent()")
                    print(error.localizedDescription)
                }
            }
        }
        
        torrents[hash] = nil

        if notify {
            NotificationCenter.default.post(name: .torrentRemoved, object: [hash])
        }
    }

    private func removeTorrentFile(hash: String) {
        let files = try? FileManager.default.contentsOfDirectory(atPath: Core.configFolder).filter { $0.hasSuffix(".torrent") }
        for file in files ?? [] {
            if hash == TorrentSdk.getTorrentFileHash(torrentPath: Core.configFolder + "/" + file) {
                try? FileManager.default.removeItem(atPath: Core.configFolder + "/" + file)
                break
            }
        }
    }
}
