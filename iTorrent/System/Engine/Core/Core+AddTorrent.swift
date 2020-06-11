//
//  Core+AddTorrent.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

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

    func addTorrentFromFile(_ filePath: URL) {
        if var nav = (Utils.topViewController as? UINavigationController)?.topViewController {
            while let presentedViewController = nav.presentedViewController {
                nav = presentedViewController
            }
            if nav is AddTorrentController {
                let controller = ThemedUIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                         message: Localize.get("Finish the previous torrent adding before start the new one."),
                                                         preferredStyle: .alert)
                let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                controller.addAction(close)
                nav.present(controller, animated: true)

                return
            }
        }

        DispatchQueue.global(qos: .background).async {
            while self.state != .InProgress {
                sleep(1)
            }
            DispatchQueue.main.async {
                let dest = Core.configFolder + "/_temp.torrent"
                print(filePath.startAccessingSecurityScopedResource())
                do {
                    if FileManager.default.fileExists(atPath: dest) {
                        try FileManager.default.removeItem(atPath: dest)
                    }
                    print(FileManager.default.fileExists(atPath: filePath.path))
                    try FileManager.default.copyItem(at: filePath, to: URL(fileURLWithPath: dest))
                } catch {
                    let controller = ThemedUIAlertController(title: NSLocalizedString("Error on torrent opening", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    Utils.topViewController?.present(controller, animated: true)

                    return
                }
                filePath.stopAccessingSecurityScopedResource()

                let hash = TorrentSdk.getTorrentFileHash(torrentPath: dest)!
                if hash == "-1" {
                    let controller = ThemedUIAlertController(title: Localize.get("Error on torrent reading"),
                                                             message: Localize.get("Torrent file opening error has been occured"),
                                                             preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    Utils.topViewController?.present(controller, animated: true)
                    return
                } else if self.torrents[hash] != nil {
                    let controller = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                                                             message: "\(Localize.get("Torrent with hash:")) \"\(hash)\" \(Localize.get("already exists in download queue"))",
                                                             preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    Utils.topViewController?.present(controller, animated: true)
                    return
                }
                do {
                    if let controller = UIApplication.shared.keyWindow?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "AddTorrent") as? UINavigationController {
                        (controller.topViewController as? AddTorrentController)?.initialize(filePath: dest)
                        Utils.topViewController?.present(controller, animated: true)
                    }
                }
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
                        self.torrents[hash] != nil {
                        let alert = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                                                            message: "\(Localize.get("Torrent with hash:")) \"\(hash)\" \(Localize.get("already exists in download queue"))",
                                                            preferredStyle: .alert)
                        let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                        alert.addAction(close)
                        Utils.topViewController?.present(alert, animated: true)
                    } else if let hash = TorrentSdk.addMagnet(magnetUrl: magnetLink) {
                        print(hash)
                        self.torrentsUserData[hash] = UserManagerSettings()
                        self.mainLoop()
                    } else {
                        let controller = ThemedUIAlertController(title: Localize.get("Error"),
                                                                 message: Localize.get("Wrong magnet link, check it and try again!"),
                                                                 preferredStyle: .alert)
                        let close = UIAlertAction(title: NSLocalizedString(NSLocalizedString("Close", comment: ""), comment: ""), style: .cancel)
                        controller.addAction(close)
                        Utils.topViewController?.present(controller, animated: true)
                    }
                }
            }
        }
    }
    
    func addFromUrl(_ url: String, presenter: UIViewController) {
        Utils.checkFolderExist(path: Core.configFolder)

        if let url = URL(string: url) {
            Downloader.load(url: url, to: URL(fileURLWithPath: Core.configFolder + "/_temp.torrent"), completion: {
                let hash = TorrentSdk.getTorrentFileHash(torrentPath: Core.configFolder + "/_temp.torrent")
                if hash == nil || hash == "-1" {
                    let controller = ThemedUIAlertController(title: Localize.get("Error has been occured"),
                                                             message: Localize.get("Torrent file is broken or this URL has some sort of DDOS protection, you can try to open this link in Safari"),
                                                             preferredStyle: .alert)
                    let safari = UIAlertAction(title: NSLocalizedString("Open in Safari", comment: ""), style: .default) { _ in
                        UIApplication.shared.openURL(url)
                    }
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(safari)
                    controller.addAction(close)
                    Utils.topViewController?.present(controller, animated: true)
                    return
                }
                if Core.shared.torrents[hash!] != nil {
                    let controller = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                                                             message: "\(Localize.get("Torrent with hash:")) \"\(hash!)\" \(Localize.get("already exists in download queue"))",
                                                             preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    Utils.topViewController?.present(controller, animated: true)
                    return
                }
                let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
                ((controller as? UINavigationController)?.topViewController as? AddTorrentController)?.initialize(filePath: Core.configFolder + "/_temp.torrent")
                presenter.present(controller, animated: true)
            }, errorAction: {
                let alertController = ThemedUIAlertController(title: Localize.get("Error has been occured"),
                                                              message: Localize.get("Please, open this link in Safari, and send .torrent file from there"),
                                                              preferredStyle: .alert)
                let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                alertController.addAction(close)
                presenter.present(alertController, animated: true)
            })
        } else {
            let alertController = ThemedUIAlertController(title: Localize.get("Error"),
                                                          message: Localize.get("Wrong link, check it and try again!"),
                                                          preferredStyle: .alert)
            let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
            alertController.addAction(close)
            presenter.present(alertController, animated: true)
        }
    }
}
