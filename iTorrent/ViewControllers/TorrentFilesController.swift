//
//  TorrentFilesController.swift
//  iTorrent
//
//  Created by  XITRIX on 16.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TorrentFilesController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var managerHash : String!
    
    var name : String = ""
	var files : [FileInfo] = []
	var sortMask : [Int] = []
	var fileSelectes : [Int32] = []
    
    var folders : [String : [Int]] = [:]
    var foldersSize : [String : Int64] = [:]
    var showFiles : [Int] = []
    var showSortMask : [Int] = []
    
    var root : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (root == nil) {
            root = name + "/"
        }
		
//        initialize()
//        update()
		
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 78
        
//        tableView.reloadData()
		
        DispatchQueue.global(qos: .background).async {
            while(true) {
                DispatchQueue.main.async {
                    self.update()
                }
                sleep(1)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        initialize()
        update()
        
        tableView.reloadData()
    }
    
    deinit {
        print("DEINIT!!")
    }
	
	func initialize() {
        files.removeAll()
        sortMask.removeAll()
        fileSelectes.removeAll()
        
        showSortMask.removeAll()
        folders.removeAll()
        foldersSize.removeAll()
        showFiles.removeAll()
        
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
        
        name = String(validatingUTF8: localFiles.title) ?? "ERROR"
        let size = Int(localFiles.size)
        let namesArr = Array(UnsafeBufferPointer(start: localFiles.file_name, count: size))
        let pathsArr = Array(UnsafeBufferPointer(start: localFiles.file_path, count: size))
        let sizesArr = Array(UnsafeBufferPointer(start: localFiles.file_size, count: size))
        
        for i in 0 ..< size {
            fileSelectes.append(localFiles.file_priority[Int(i)])
            
            let file = FileInfo()
            let name = String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR"
            
            let cutName = name.replacingOccurrences(of: root, with: "")
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
            //name = name.replacingOccurrences(of: self.name + "/" + root, with: "")
            //name = String(name.split(separator: "/").last!)
            file.fileName = cutName
            file.filePath = String(validatingUTF8: pathsArr[Int(i)]!) ?? "ERROR"
            file.fileSize = sizesArr[i]
            file.fileDownloaded = localFiles.file_downloaded[i]
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
	}
	
	func update() {
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
		
		name = String(validatingUTF8: localFiles.title) ?? "ERROR"
		let size = Int(localFiles.size)
		let sizesArr = Array(UnsafeBufferPointer(start: localFiles.file_size, count: size))
		
		for i in 0 ..< size {
			files[i].fileSize = sizesArr[i]
			files[i].fileDownloaded = localFiles.file_downloaded[i]
		}
		
		DispatchQueue.main.async {
			for cell in self.tableView.visibleCells {
                if let cell = cell as? FileCell {
                    cell.file = self.files[self.showSortMask[cell.index]]
                    cell.update()
                }
			}
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
            cell.action = { more in
                let controller = UIAlertController(title: "Download content of folder", message: key, preferredStyle: .actionSheet)
                
                let download = UIAlertAction(title: "Download", style: .default) { alert in
                    for i in self.folders[key]! {
                        self.fileSelectes[i] = 4
                    }
                    set_torrent_files_priority(self.managerHash, UnsafeMutablePointer(mutating: self.fileSelectes))
                }
                let notDownload = UIAlertAction(title: "Don't Download", style: .destructive) { alert in
                    for i in self.folders[key]! {
                        if (self.files[i].fileDownloaded / self.files[i].fileSize == 1) {
                            self.fileSelectes[i] = 4
                        } else {
                            self.fileSelectes[i] = 0
                        }
                    }
                    set_torrent_files_priority(self.managerHash, UnsafeMutablePointer(mutating: self.fileSelectes))
                }
                let cancel = UIAlertAction(title: "Close", style: .cancel)
                
                controller.addAction(download)
                controller.addAction(notDownload)
                controller.addAction(cancel)
                
                if (controller.popoverPresentationController != nil) {
                    controller.popoverPresentationController?.sourceView = more;
                    controller.popoverPresentationController?.sourceRect = more.bounds;
                    controller.popoverPresentationController?.permittedArrowDirections = .any;
                }
                
                self.present(controller, animated: true)
            }
            return cell
        } else {
            let index = indexPath.row - folders.keys.count
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
            cell.file = files[showSortMask[index]]
            cell.name = name
            cell.index = index
            cell.update()
            cell.switcher.setOn(fileSelectes[showSortMask[index]] != 0, animated: false)
            cell.action = { switcher in
                self.fileSelectes[self.showSortMask[index]] = switcher.isOn ? 4 : 0
                set_torrent_file_priority(self.managerHash, Int32(self.showSortMask[index]), switcher.isOn ? 4 : 0)
            }
            return cell
        }
        
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row < folders.keys.count) {
            let controller = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Files") as! TorrentFilesController
            controller.managerHash = managerHash
            controller.root = root + folders.keys.sorted()[indexPath.row] + "/"
            show(controller, sender: self)
        } else {
            let file = files[showSortMask[indexPath.row]]
            let percent = Float(file.fileDownloaded) / Float(file.fileSize) * 100
            if (percent < 100) {
                let cell = tableView.cellForRow(at: indexPath) as! FileCell
                cell.switcher.setOn(!cell.switcher.isOn, animated: true)
                cell.action(cell.switcher)
            }
        }
	}
    
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(false, animated: true)
            }
		}
		for i in 0 ..< fileSelectes.count {
			if (files[i].fileDownloaded / files[i].fileSize == 1) {
				fileSelectes[i] = 4
			} else {
				fileSelectes[i] = 0
			}
		}
        set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: fileSelectes))
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(true, animated: true)
            }
		}
		for i in 0 ..< fileSelectes.count {
			fileSelectes[i] = 4
		}
        set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: fileSelectes))
    }
}
