//
//  TorrentFilesController.swift
//  iTorrent
//
//  Created by  XITRIX on 16.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TorrentFilesController : ThemedUIViewController, UITableViewDataSource, UITableViewDelegate, FileCellActionDelegate, FolderCellActionDelegate {
    @IBOutlet weak var tableView: ThemedUITableView!
    
    var managerHash : String!
    var name : String!
    
    var filesContainer : FilesContainer!
    
    var folders : [String : [Int]] = [:]
    var foldersSize : [String : Int64] = [:]
    var showFiles : [Int] = []
    var showSortMask : [Int] = []
    
    var root : String!
    
    var runUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (root == nil) {
            root = name + "/"
            
            let but = UIBarButtonItem()
            but.title = name
            navigationItem.backBarButtonItem = but
        } else {
            title = URL(fileURLWithPath: root).lastPathComponent
        }
        
        if (filesContainer == nil) {
            filesContainer = FilesContainer()
            initialize()
        } else {
            initFolders()
        }
		
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 78
    }
    
    override func viewWillAppear(_ animated: Bool) {
        runUpdate = true
        DispatchQueue.global(qos: .background).async {
            while(self.runUpdate) {
                DispatchQueue.main.async {
                    self.update()
                    
                    for cell in self.tableView.visibleCells {
                        if let cell = cell as? FileCell {
                            cell.file = self.filesContainer.files[self.showSortMask[cell.index]]
                            cell.update()
                        }
                    }
                }
                
                sleep(1)
            }
        }
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        runUpdate = false
    }
    
    deinit {
        print("Files DEINIT!!")
    }
	
	func initialize() {
        filesContainer.files.removeAll()
        filesContainer.sortMask.removeAll()
        filesContainer.fileSelectes.removeAll()
        
        showSortMask.removeAll()
        folders.removeAll()
        foldersSize.removeAll()
        showFiles.removeAll()
        
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
        }
        
        filesContainer.name = String(validatingUTF8: localFiles.title) ?? "ERROR"
        let size = Int(localFiles.size)
        let namesArr = Array(UnsafeBufferPointer(start: localFiles.file_name, count: size))
        let pathsArr = Array(UnsafeBufferPointer(start: localFiles.file_path, count: size))
        let sizesArr = Array(UnsafeBufferPointer(start: localFiles.file_size, count: size))
        
        for i in 0 ..< size {
            filesContainer.fileSelectes.append(localFiles.file_priority[Int(i)])
            
            let file = FileInfo()
            let name = String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR"
            
            var cutName = name
            if (cutName.hasPrefix(root)) {
                cutName = String(cutName.dropFirst(root.count))
            }
            
            if (root == self.filesContainer.name + "/" || name.contains(root)) {
                let nameParts = cutName.split(separator: "/")
                if (nameParts.count > 1) {
                    if (folders[String(nameParts[0])] == nil) {
                        folders[String(nameParts[0])] = []
                    }
                    folders[String(nameParts[0])]?.append(i)
                } else {
                    showFiles.append(i)
                }
            }
            
            file.fileName = cutName
            file.filePath = String(validatingUTF8: pathsArr[Int(i)]!) ?? "ERROR"
            file.fileSize = sizesArr[i]
            file.fileDownloaded = localFiles.file_downloaded[i]
            filesContainer.files.append(file)
        }
        
        for f in folders {
            var size : Int64 = 0
            for s in f.value {
                size += filesContainer.files[s].fileSize
            }
            foldersSize[f.key] = size
        }
        
        let sort = filesContainer.files.sorted(by: {$0.fileName < $1.fileName})
        for i in 0 ..< sort.count {
            let index = filesContainer.files.index(where: {$0.fileName == sort[i].fileName})!
            if (showFiles.contains(index)) {
                showSortMask.append(index)
            }
            filesContainer.sortMask.append(index)
        }
	}
    
    func initFolders() {
        showSortMask.removeAll()
        folders.removeAll()
        foldersSize.removeAll()
        showFiles.removeAll()
        
        for i in 0 ..< filesContainer.files.count {
            var cutName = filesContainer.files[i].filePath
            if (cutName.hasPrefix(root)) {
                cutName = String(cutName.dropFirst(root.count))
            }
            
            if (root == filesContainer.name + "/" || filesContainer.files[i].filePath.contains(root)) {
                let nameParts = cutName.split(separator: "/")
                if (nameParts.count > 1) {
                    if (folders[String(nameParts[0])] == nil) {
                        folders[String(nameParts[0])] = []
                    }
                    folders[String(nameParts[0])]?.append(i)
                } else {
                    showFiles.append(i)
                    filesContainer.files[i].fileName = cutName
                }
            }
            
        }
        
        for f in folders {
            var size : Int64 = 0
            for s in f.value {
                size += filesContainer.files[s].fileSize
            }
            foldersSize[f.key] = size
        }
        
        let sort = filesContainer.files.sorted(by: {$0.fileName < $1.fileName})
        for i in 0 ..< sort.count {
            let index = filesContainer.files.index(where: {$0.fileName == sort[i].fileName})!
            if (showFiles.contains(index)) {
                showSortMask.append(index)
            }
            filesContainer.sortMask.append(index)
        }
    }
	
	func update() {
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
		
		filesContainer.name = String(validatingUTF8: localFiles.title) ?? "ERROR"
		let size = Int(localFiles.size)
		let sizesArr = Array(UnsafeBufferPointer(start: localFiles.file_size, count: size))
		
		for i in 0 ..< size {
			filesContainer.files[i].fileSize = sizesArr[i]
			filesContainer.files[i].fileDownloaded = localFiles.file_downloaded[i]
		}
	}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.keys.count + showFiles.count
        //return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if (indexPath.row < folders.keys.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderCell
            let key = folders.keys.sorted()[indexPath.row]
            cell.title.text = key
            cell.size.text = Utils.getSizeText(size: foldersSize[key]!)
            cell.actionDelegate = self
			cell.updateTheme()
            return cell
        } else {
            let index = indexPath.row - folders.keys.count
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
            cell.file = filesContainer.files[showSortMask[index]]
            cell.name = filesContainer.name
            cell.index = index
            cell.update()
            cell.switcher.setOn(filesContainer.fileSelectes[showSortMask[index]] != 0, animated: false)
            cell.actionDelegate = self
			cell.updateTheme()
            return cell
        }
        
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row < folders.keys.count) {
            let controller = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Files") as! TorrentFilesController
            controller.managerHash = managerHash
            controller.name = name
            controller.root = root + folders.keys.sorted()[indexPath.row] + "/"
            controller.filesContainer = filesContainer
            show(controller, sender: self)
        } else {
            let index = indexPath.row - folders.keys.count
            let file = filesContainer.files[showSortMask[indexPath.row]]
            let percent = Float(file.fileDownloaded) / Float(file.fileSize) * 100
            if (percent < 100) {
                let cell = tableView.cellForRow(at: indexPath) as! FileCell
                cell.switcher.setOn(!cell.switcher.isOn, animated: true)
                if (cell.actionDelegate != nil) {
                    cell.actionDelegate?.fileCellAction(cell.switcher, index: index)
                }
            }
        }
	}
    
    func folderCellAction(_ key: String, sender : UIButton) {
        let controller = ThemedUIAlertController(title: "Download content of folder", message: key, preferredStyle: .actionSheet)
        
        let download = UIAlertAction(title: "Download", style: .default) { alert in
            for i in self.folders[key]! {
                self.filesContainer.fileSelectes[i] = 4
            }
            set_torrent_files_priority(self.managerHash, UnsafeMutablePointer(mutating: self.filesContainer.fileSelectes))
        }
        let notDownload = UIAlertAction(title: "Don't Download", style: .destructive) { alert in
            for i in self.folders[key]! {
                if (self.filesContainer.files[i].fileSize != 0 && self.filesContainer.files[i].fileDownloaded / self.filesContainer.files[i].fileSize == 1) {
                    self.filesContainer.fileSelectes[i] = 4
                } else {
                    self.filesContainer.fileSelectes[i] = 0
                }
            }
            set_torrent_files_priority(self.managerHash, UnsafeMutablePointer(mutating: self.filesContainer.fileSelectes))
        }
        let cancel = UIAlertAction(title: "Close", style: .cancel)
        
        controller.addAction(download)
        controller.addAction(notDownload)
        controller.addAction(cancel)
        
        if (controller.popoverPresentationController != nil) {
            controller.popoverPresentationController?.sourceView = sender;
            controller.popoverPresentationController?.sourceRect = sender.bounds;
            controller.popoverPresentationController?.permittedArrowDirections = .any;
        }
        
        self.present(controller, animated: true)
    }
    
    func fileCellAction(_ sender: UISwitch, index: Int) {
        filesContainer.fileSelectes[showSortMask[index]] = sender.isOn ? 4 : 0
        set_torrent_file_priority(managerHash, Int32(showSortMask[index]), sender.isOn ? 4 : 0)
    }
    
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(false, animated: true)
            }
		}
		for i in 0 ..< filesContainer.fileSelectes.count {
			if (filesContainer.files[i].fileSize != 0 && filesContainer.files[i].fileDownloaded / filesContainer.files[i].fileSize == 1) {
				filesContainer.fileSelectes[i] = 4
			} else {
				filesContainer.fileSelectes[i] = 0
			}
		}
        set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: filesContainer.fileSelectes))
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(true, animated: true)
            }
		}
		for i in 0 ..< filesContainer.fileSelectes.count {
			filesContainer.fileSelectes[i] = 4
		}
        set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: filesContainer.fileSelectes))
    }
}

class FilesContainer {
    var name : String = ""
    var files : [FileInfo] = []
    var sortMask : [Int] = []
    var fileSelectes : [Int32] = []
}
