//
//  AddTorrentController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class AddTorrentController : ThemedUIViewController, UITableViewDataSource, UITableViewDelegate, FileCellActionDelegate, FolderCellActionDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var path : String!
    
    var name : String = ""
    var files : [FileInfo] = []
    var sortMask : [Int] = []
    var fileSelectes : FileSelectes!
    
    var folders : [String : [Int]] = [:]
    var foldersSize : [String : Int64] = [:]
    var showFiles : [Int] = []
    var showSortMask : [Int] = []
    
    var root : String!
	
	override func updateTheme() {
		super.updateTheme()
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		tableView.backgroundColor = Themes.shared.theme[theme].backgroundMain
	}
    
    deinit {
        print("Add Torrent DEINIT!!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let localFiles = get_files_of_torrent_by_path(path)
		
		let size = Int(localFiles.size)
		if (size == -1) {
			let controller = ThemedUIAlertController(title: "Error has been occured", message: "Torrent file is broken and cannot be readed", preferredStyle: .alert)
			let close = UIAlertAction(title: "Close", style: .cancel) { _ in
				self.dismiss(animated: true)
			}
			controller.addAction(close)
			present(controller, animated: true)
			return
		}
        name = String(validatingUTF8: localFiles.title) ?? "ERROR"
        let namesArr = Array(UnsafeBufferPointer(start: localFiles.file_name, count: size))
        let sizesArr = Array(UnsafeBufferPointer(start: localFiles.file_size, count: size))
        
        if (root == nil) {
            root = name + "/"
        }
        
        if (fileSelectes == nil) {
            fileSelectes = FileSelectes()
            for _ in 0 ..< size {
                fileSelectes.fileSelectes.append(4)
            }
        }
        
        for i in 0 ..< size {
            let file = FileInfo()
            let name = String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR"
            
            var cutName = name
            if (cutName.hasPrefix(root)) {
                cutName = String(cutName.dropFirst(root.count))
            }
            
            if (root == self.name + "/" || name.contains(root)) {
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
            file.fileSize = sizesArr[i]
            files.append(file)
        }
        
        for f in folders {
            var size : Int64 = 0
            for s in f.value {
                size += files[s].fileSize
            }
            foldersSize[f.key] = size
        }
        
        let sort = files.sorted(by: {$0.fileName < $1.fileName})
        for i in 0 ..< sort.count {
            let index = files.index(where: {$0.fileName == sort[i].fileName})!
            if (showFiles.contains(index)) {
                showSortMask.append(index)
            }
            sortMask.append(index)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 78
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.keys.count + showFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row < folders.keys.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderCell
            let key = folders.keys.sorted()[indexPath.row]
            cell.title.text = key
            cell.size.text = Utils.getSizeText(size: foldersSize[key]!)
            cell.actionDelegate = self
            return cell
        } else {
            let index = indexPath.row - folders.keys.count
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
            cell.file = files[showSortMask[index]]
            cell.name = name
            cell.index = index
            cell.addind = true
            cell.update()
            cell.switcher.setOn(fileSelectes.fileSelectes[showSortMask[index]] != 0, animated: false)
            cell.actionDelegate = self
            return cell
        }
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row < folders.keys.count) {
            let controller = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrentView") as! AddTorrentController
            controller.path = path
            controller.root = root + folders.keys.sorted()[indexPath.row] + "/"
            controller.navigationItem.setLeftBarButton(nil, animated: false)
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            controller.fileSelectes = fileSelectes
            show(controller, sender: self)
        } else {
            let index = indexPath.row - folders.keys.count
            let cell = tableView.cellForRow(at: indexPath) as! FileCell
            cell.switcher.setOn(!cell.switcher.isOn, animated: true)
            if (cell.actionDelegate != nil) {
                cell.actionDelegate?.fileCellAction(cell.switcher, index: index)
            }
        }
	}
    
    func folderCellAction(_ key: String, sender: UIButton) {
        let controller = ThemedUIAlertController(title: "Download content of folder", message: key, preferredStyle: .actionSheet)
        
        let download = UIAlertAction(title: "Download", style: .default) { alert in
            for i in self.folders[key]! {
                self.fileSelectes.fileSelectes[i] = 4
            }
        }
        let notDownload = UIAlertAction(title: "Don't Download", style: .destructive) { alert in
            for i in self.folders[key]! {
                if (self.files[i].fileDownloaded / self.files[i].fileSize == 1) {
                    self.fileSelectes.fileSelectes[i] = 4
                } else {
                    self.fileSelectes.fileSelectes[i] = 0
                }
            }
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
        fileSelectes.fileSelectes[showSortMask[index]] = sender.isOn ? 4 : 0
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        if (FileManager.default.fileExists(atPath: Manager.configFolder+"/_temp.torrent")) {
            try! FileManager.default.removeItem(atPath: Manager.configFolder+"/_temp.torrent")
        }
        dismiss(animated: true)
    }
	
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(false, animated: true)
            }
		}
		for i in 0 ..< fileSelectes.fileSelectes.count {
			fileSelectes.fileSelectes[i] = 0
		}
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(true, animated: true)
            }
		}
		for i in 0 ..< fileSelectes.fileSelectes.count {
			fileSelectes.fileSelectes[i] = 4
		}
    }
	
    @IBAction func downloadAction(_ sender: UIBarButtonItem) {
        let urlPath = URL(fileURLWithPath: path)
        let urlRes = urlPath.deletingLastPathComponent().appendingPathComponent(name+".torrent")
		if (FileManager.default.fileExists(atPath: urlRes.path)) {
			try! FileManager.default.removeItem(at: urlRes)
		}
		do {
			try FileManager.default.copyItem(at: urlPath, to: urlRes)
			if (path.hasSuffix("_temp.torrent")) {
				try FileManager.default.removeItem(atPath: Manager.configFolder+"/_temp.torrent")
			}
			dismiss(animated: true)
			let hash = String(validatingUTF8: get_torrent_file_hash(urlRes.path)) ?? "ERROR"
			add_torrent_with_states(urlRes.path, UnsafeMutablePointer(mutating: fileSelectes.fileSelectes))
			Manager.managerSaves[hash] = UserManagerSettings()
		} catch {
			let controller = ThemedUIAlertController(title: "Error has been occured", message: error.localizedDescription, preferredStyle: .alert)
			let close = UIAlertAction(title: "Close", style: .cancel)
			controller.addAction(close)
			present(controller, animated: true)
		}
    }
}

class FileSelectes {
    var fileSelectes : [Int32] = []
}
