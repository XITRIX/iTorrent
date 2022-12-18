//
//  Core_TorrentBackup.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import Foundation

extension Core {
    func saveTorrents(filesStatesOnly: Bool = true) {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: torrentsUserData)
        do {
            try encodedData.write(to: URL(fileURLWithPath: Core.fastResumesFolder + "/userData.dat"))
        } catch {
            print("Couldn't write file")
        }
        if !filesStatesOnly {
            TorrentSdk.saveFastResume()
        }
    }
    
    func restoreAllTorrents() {
        Utils.checkFolderExist(path: Core.configFolder)
        Utils.checkFolderExist(path: Core.fastResumesFolder)

        if let loadedStrings = NSKeyedUnarchiver.unarchiveObject(withFile: Core.fastResumesFolder + "/userData.dat") as? [String: UserManagerSettings] {
            print("resumed")
            torrentsUserData = loadedStrings
        }

        if let files = try? FileManager.default.contentsOfDirectory(atPath: Core.configFolder).filter({ $0.hasSuffix(".torrent") }) {
            for file in files {
                if file == "_temp.torrent" {
                    continue
                }
                addTorrent(Core.configFolder + "/" + file)
            }
        } else {
            // TODO: Error handler
        }
    }
}
