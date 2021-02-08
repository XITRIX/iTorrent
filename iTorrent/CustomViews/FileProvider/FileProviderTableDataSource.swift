//
//  FileProviderTableDataSource.swift
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
import UIKit

class FileProviderTableDataSource: NSObject {
    var path: URL!
    var data: [FileModel]!
    
    var folders: [FolderModel]!
    var files: [FileModel]!
    
    weak var delegate: FileProviderDelegate?
    weak var tableView: UITableView?
    
    init(tableView: UITableView, path: URL, data: [FileModel]) {
        super.init()
        
        self.tableView = tableView
        self.data = data
        self.path = path
        files = data.filter { $0.path.deletingLastPathComponent().path == path.path }.sorted { $0.name < $1.name }
        folders = getFolders(from: files)
        
        // if multifile torrent, open first folder by default
        if path.pathComponents.count == 1,
            folders.count == 1 {
            self.path = folders[0].path
            files = data.filter { $0.path.deletingLastPathComponent().path == self.path.path }.sorted { $0.name < $1.name }
            folders = getFolders(from: files)
        }
        
        tableView.register(FolderCell.nib, forCellReuseIdentifier: FolderCell.id)
        tableView.register(FileCell.nib, forCellReuseIdentifier: FileCell.id)
        tableView.estimatedRowHeight = 78
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func getFolders(from files: [FileModel]) -> [FolderModel] {
        var foldersDict = [String: FolderModel]()
        
        for file in data {
            if file.path.path.starts(with: path.path),
                file.path.pathComponents.count > path.pathComponents.count + 1 {
                let folderName = String(file.path.pathComponents[path.pathComponents.count])
                if foldersDict[folderName] == nil {
                    let folder = FolderModel()
                    folder.name = folderName
                    folder.path = path.appendingPathComponent(folderName)
                    foldersDict[folderName] = folder
                }
                foldersDict[folderName]?.files.append(file)
            }
        }
        
        for folder in foldersDict.values {
            var size: Int64 = 0
            var downloaded: Int64 = 0
            for file in folder.files {
                size += file.size
                if file.downloadedBytes != nil {
                    downloaded += file.downloadedBytes
                }
            }
            folder.size = size
            folder.downloadedSize = downloaded
            folder.isPreview = folder.files.first?.isPreview ?? true
        }
        
        return Array(foldersDict.values).sorted { $0.name < $1.name }
    }
    
    func update() {
        tableView?.visibleCells.forEach { ($0 as? UpdatableModel)?.updateModel() }
    }
    
    func selectAll() {
        data.forEach { $0.priority = .normalPriority }
        setAllSwitchElements(enabled: true)
    }
    
    func deselectAll() {
        data.forEach { file in
            if file.size != 0, file.downloadedBytes == file.size {
                file.priority = .normalPriority
            } else {
                file.priority = .dontDownload
            }
        }
        setAllSwitchElements(enabled: false)
    }
    
    private func setAllSwitchElements(enabled: Bool) {
        tableView?.visibleCells.forEach { cell in
            if let fileCell = cell as? FileCell {
                fileCell.prioritySwitch.setOn(enabled, animated: true)
                fileCell.setSwitchColor()
            }
        }
        
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}

extension FileProviderTableDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        folders.count + files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if folders.count > indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: FolderCell.id, for: indexPath) as! FolderCell
            cell.setModel(folders[indexPath.row])
            cell.moreAction = { [weak self] folder in
                self?.delegate?.folderPriorityChanged(folder: folder)
            }
            return cell
        } else {
            let fileIdx = indexPath.row - folders.count
            let cell = tableView.dequeueReusableCell(withIdentifier: FileCell.id, for: indexPath) as! FileCell
            cell.setModel(files[fileIdx])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if !tableView.isEditing {
            if indexPath.row < folders.count {
                return false
            } else {
                let file = files[indexPath.row - folders.count]
                if file.downloadedBytes == file.size {
                    return false
                }
            }
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let title = NSLocalizedString("Priority", comment: "")
        let button = UITableViewRowAction(style: .default, title: title) { _, indexPath in
            let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Priority", comment: ""), preferredStyle: .actionSheet)

            let high = UIAlertAction(title: NSLocalizedString("High", comment: ""), style: .default, handler: { _ in
                updateCell(indexPath, .highPriority)
            })
            let norm = UIAlertAction(title: NSLocalizedString("Normal", comment: ""), style: .default, handler: { _ in
                updateCell(indexPath, .normalPriority)
            })
            let low = UIAlertAction(title: NSLocalizedString("Low", comment: ""), style: .default, handler: { _ in
                updateCell(indexPath, .lowPriority)
            })
            
            func updateCell(_ indexPath: IndexPath, _ priority: FileModel.TorrentDownloadPriority) {
                let file = self.files[indexPath.row - self.folders.count]
                file.priority = priority
                (tableView.cellForRow(at: indexPath) as? UpdatableModel)?.updateModel()
                self.delegate?.fileActionCalled(file: file)
            }

            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

            controller.addAction(high)
            controller.addAction(norm)
            controller.addAction(low)
            controller.addAction(cancel)

            if controller.popoverPresentationController != nil {
                controller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                controller.popoverPresentationController?.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
                controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            }

            Utils.topViewController?.present(controller, animated: true)
        }
        button.backgroundColor = #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)
        //(tableView.cellForRow(at: indexPath) as? FileCell)?.update()
        return [button]
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        tableView.isEditing
    }
}

extension FileProviderTableDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if folders.count > indexPath.row {
                delegate?.folderSelected(folder: folders[indexPath.row])
            } else {
                let fileIdx = indexPath.row - folders.count
                let cell = tableView.cellForRow(at: indexPath) as! FileCell
                cell.onClick()
                delegate?.fileSelected(file: files[fileIdx])
            }
        }
    }
}
