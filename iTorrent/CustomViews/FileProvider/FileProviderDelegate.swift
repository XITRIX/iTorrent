//
//  FileProviderDelegate.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif
import Foundation

protocol FileProviderDelegate: NSObjectProtocol {
    func fileSelected(file: FileModel)
    func folderSelected(folder: FolderModel)
    func folderPriorityChanged(folder: FolderModel)
    func fileActionCalled(file: FileModel)
}
