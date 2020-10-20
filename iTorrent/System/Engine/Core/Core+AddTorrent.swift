//
//  Core+AddTorrent.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

extension Core {
    func addTorrent(_ filePath: String) {
        if let hash = TorrentSdk.addTorrent(torrentPath: filePath) {
            if torrentsUserData[hash] == nil {
                print(hash)
                torrentsUserData[hash] = UserManagerSettings()
            }
        } else {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                print(error.localizedDescription)
            }
        }
        mainLoop()
    }

    func addTorrentFromFile(_ filePath: URL, openInPlace: Bool = false) {
        if var nav = (Utils.topViewController as? UINavigationController)?.topViewController {
            while let presentedViewController = nav.presentedViewController {
                nav = presentedViewController
            }
            if nav is AddTorrentController {
                Dialog.show(nav,
                            title: "Error",
                            message: "Finish the previous torrent adding before start the new one.")
                return
            }
        }

        DispatchQueue.global(qos: .background).async {
            while self.state != .InProgress {
                sleep(1)
            }
            DispatchQueue.main.async {
                let dest = Core.tempFile
                do {
                    if FileManager.default.fileExists(atPath: dest) {
                        try FileManager.default.removeItem(atPath: dest)
                    }
                    if openInPlace {
                        _ = filePath.startAccessingSecurityScopedResource()
                        try FileManager.default.copyItem(at: filePath, to: URL(fileURLWithPath: dest))
                        filePath.stopAccessingSecurityScopedResource()
                    } else {
                        try FileManager.default.moveItem(at: filePath, to: URL(fileURLWithPath: dest))
                    }
                } catch {
                    Dialog.show(title: "Error on torrent opening",
                                message: error.localizedDescription)
                    return
                }

                guard let hash = TorrentSdk.getTorrentFileHash(torrentPath: dest) else {
                    Dialog.show(title: "Error",
                                message: "Torrent file opening error has been occured")
                    return
                }

                if self.torrents[hash] != nil {
                    Dialog.show(title: "This torrent already exists",
                                message: "\(Localize.get("Torrent with hash:")) \"\(hash)\" \(Localize.get("already exists in download queue"))")
                    return
                }

                let controller = AddTorrentController(filePath: dest)
                Utils.topViewController?.present(controller.embedInNavigation(), animated: true)
            }
        }
    }

    func addMagnet(_ magnetLink: String) {
        if magnetLink.starts(with: "magnet:") {
            DispatchQueue.global(qos: .background).async {
                while self.state != .InProgress {
                    sleep(1)
                }
                DispatchQueue.main.async {
                    if let hash = TorrentSdk.getMagnetHash(magnetUrl: magnetLink),
                        self.torrents[hash] != nil
                    {
                        Dialog.show(title: "This torrent already exists",
                                    message: "\(Localize.get("Torrent with hash:")) \"\(hash)\" \(Localize.get("already exists in download queue"))")
                    } else if let hash = TorrentSdk.addMagnet(magnetUrl: magnetLink) {
                        print(hash)
                        self.torrentsUserData[hash] = UserManagerSettings()
                        self.mainLoop()
                    } else {
                        Dialog.show(title: "Error",
                                    message: "Wrong magnet link, check it and try again!")
                    }
                }
            }
        }
    }

    func addFromUrl(_ url: String, presenter: UIViewController) {
        Utils.checkFolderExist(path: Core.configFolder)

        if let url = URL(string: url) {
            Downloader.load(url: url, to: URL(fileURLWithPath: Core.tempFile), completion: {
                let hash = TorrentSdk.getTorrentFileHash(torrentPath: Core.tempFile)
                if hash == nil || hash == "-1" {
                    Dialog.withButton(title: "Error has been occured",
                                      message: "Torrent file is broken or this URL has some sort of DDOS protection, you can try to open this link in Safari",
                                      okTitle: "Open in Safari") {
                        UIApplication.shared.openURL(url)
                    }
                    return
                }

                if Core.shared.torrents[hash!] != nil {
                    Dialog.show(title: "This torrent already exists",
                                message: "\(Localize.get("Torrent with hash:")) \"\(hash!)\" \(Localize.get("already exists in download queue"))")
                    return
                }

                let controller = AddTorrentController(filePath: Core.tempFile)
                presenter.present(controller.embedInNavigation(), animated: true)
            }, errorAction: {
                Dialog.show(presenter,
                            title: "Error has been occured",
                            message: "Please, open this link in Safari, and send .torrent file from there")
            })
        } else {
            Dialog.show(presenter,
                        title: "Error",
                        message: "Wrong link, check it and try again!")
        }
    }

    func getTorrent(by url: String, result: @escaping (Result<String, MessageError>) -> ()) {
        Utils.checkFolderExist(path: Core.configFolder)

        if let url = URL(string: url) {
            Downloader.load(url: url, to: URL(fileURLWithPath: Core.tempFile), completion: {
                let hash = TorrentSdk.getTorrentFileHash(torrentPath: Core.tempFile)
                if hash == nil || hash == "-1" {
                    return result(.failure(.error("Torrent file is broken or this URL has some sort of DDOS protection, you can try to open this link in Safari".localized)))
                }

                if Core.shared.torrents[hash!] != nil {
                    return result(.failure(.error("\(Localize.get("Torrent with hash:")) \"\(hash!)\" \(Localize.get("already exists in download queue"))")))
                }

                result(.success(Core.tempFile))
            }, errorAction: {
                result(.failure(.error("Please, open this link in Safari, and send .torrent file from there".localized)))
            })
        } else {
            result(.failure(.error("Wrong link, check it and try again!".localized)))
        }
    }
}
