//
//  AddTorrentController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class AddTorrentController : ThemedUIViewController {
    
    @IBOutlet var tableView: UITableView!
	@IBOutlet weak var weightLabel: UIBarButtonItem! {
		didSet {
			weightLabel.tintColor = Themes.current().secondaryText
		}
	}
	
    var path : String!
    
    var name : String = ""
	
	var files : [File] = []
	var notSortedFiles : [File] = []
	
	var showFolders : [String:Folder] = [:]
	var showFiles : [File] = []
	
	var root : String = ""
	
	override func themeUpdate() {
		super.themeUpdate()
		tableView.backgroundColor = Themes.current().backgroundMain
	}
    
    deinit {
        print("Add Torrent DEINIT!!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		if (root.starts(with: "/")) { root.removeFirst() }
		
		if (root == "") {
			let back = UIBarButtonItem()
			back.title = NSLocalizedString("Back", comment: "")
			navigationItem.backBarButtonItem = back
			
			initialize()
		} else {
			let urlRoot = URL(string: root.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)
			title = urlRoot?.lastPathComponent
			
			let titleView = FileManagerTitleView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
			titleView.title.text = title
			titleView.subTitle.text = urlRoot?.deletingLastPathComponent().path
			navigationItem.titleView = titleView
		}
		initFolder()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 78
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
		updateWeightLabel()
    }
	
	func initialize() {
		let localFiles = get_files_of_torrent_by_path(path)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
		
		name = String(validatingUTF8: localFiles.title) ?? "ERROR"
		
		if let oldManager = Manager.torrentStates.filter({$0.title == name}).first {
			let controller = ThemedUIAlertController(title: NSLocalizedString("Torrent update detected", comment: ""), message: "\(NSLocalizedString("Torrent with name", comment: "")) \(name) \(NSLocalizedString("already exists, do you want to apply previous files selection settings to this torrent", comment: ""))?", preferredStyle: .alert)
			let apply = UIAlertAction(title: NSLocalizedString("Apply", comment: ""), style: .default) { _ in
				let oldFilesContainer = get_files_of_torrent_by_hash(oldManager.hash)
                var oldFiles : [File] = []
				
				let oldSize = Int(oldFilesContainer.size)
				
				for i in 0 ..< oldSize {
					let file = File()
					
					let n = String(validatingUTF8: oldFilesContainer.files[i].file_name) ?? "ERROR"
					let name = URL(string: n.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
					file.name = name.lastPathComponent
                    file.isDownloading = oldFilesContainer.files[Int(i)].file_priority
					file.size = oldFilesContainer.files[Int(i)].file_size
					file.downloaded = oldFilesContainer.files[Int(i)].file_downloaded
					
					oldFiles.append(file)
				}
				
				for file in self.files {
					if let oldFile = oldFiles.filter({$0.name == file.name}).first {
						file.isDownloading = oldFile.isDownloading
					}
				}
				
				self.tableView.reloadData()
			}
			let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
			
			controller.addAction(apply)
			controller.addAction(cancel)
			
			present(controller, animated: true)
		}
		
		let size = Int(localFiles.size)
		
		for i in 0 ..< size {
			let file = File()
			
			let n = String(validatingUTF8: localFiles.files[i].file_name) ?? "ERROR"
			let name = URL(string: n.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
			file.name = name.lastPathComponent
			file.path = name.deletingLastPathComponent().path == "." ? "" : name.deletingLastPathComponent().path
			file.size = localFiles.files[i].file_size
			file.isDownloading = 4
			file.number = i
			
			files.append(file)
			
			if (i == 0 && root == "" && n.starts(with: self.name + "/")) {
				root = self.name
			}
		}
		notSortedFiles = files
		files.sort{$0.name < $1.name}
	}
	
	func initFolder() {
		let rootPathParts = root.split(separator: "/")
		for file in files {
			if (file.path == root) {
				showFiles.append(file)
				continue
			}
			let filePathParts = file.path.split(separator: "/")
			if (file.path.starts(with: root + "/") && filePathParts.count > rootPathParts.count) {
				let folderName = String(filePathParts[rootPathParts.count])
				if (showFolders[folderName] == nil) {
					let folder = Folder()
					folder.name = folderName
					showFolders[folderName] = folder
				}
				let folder = showFolders[folderName]
				folder?.files.append(file)
			}
		}
		
		for folder in showFolders.keys {
			var size : Int64 = 0
			for s in (showFolders[folder]?.files)! {
				size += s.size
			}
			showFolders[folder]?.size = size
		}
	}
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        if (FileManager.default.fileExists(atPath: Manager.configFolder+"/_temp.torrent")) {
            try! FileManager.default.removeItem(atPath: Manager.configFolder+"/_temp.torrent")
        }
        dismiss(animated: true)
    }
	
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for i in 0 ..< files.count {
			if (files[i].size != 0 && files[i].size == files[i].downloaded) {
				files[i].isDownloading = 4
			} else {
				files[i].isDownloading = 0
			}
		}
		for cell in tableView.visibleCells {
			if let cell = cell as? FileCell {
				if (cell.switcher.isEnabled) {
					cell.switcher.setOn(false, animated: true)
				}
			}
		}
		updateWeightLabel()
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for i in 0 ..< files.count {
			files[i].isDownloading = 4
		}
		for cell in tableView.visibleCells {
			if let cell = cell as? FileCell {
				cell.switcher.setOn(true, animated: true)
			}
		}
		updateWeightLabel()
    }
	
    @IBAction func downloadAction(_ sender: UIBarButtonItem) {
        let urlPath = URL(fileURLWithPath: path)
        let urlRes = urlPath.deletingLastPathComponent().appendingPathComponent(name+".torrent")
		if (FileManager.default.fileExists(atPath: urlRes.path)) {
			try! FileManager.default.removeItem(at: urlRes)
		}
		for manager in Manager.torrentStates {
			if (manager.title == name) {
				remove_torrent(manager.hash, 0)
				break
			}
		}
		do {
			try FileManager.default.copyItem(at: urlPath, to: urlRes)
			if (path.hasSuffix("_temp.torrent")) {
				try FileManager.default.removeItem(atPath: Manager.configFolder+"/_temp.torrent")
			}
			dismiss(animated: true)
			let hash = String(validatingUTF8: get_torrent_file_hash(urlRes.path)) ?? "ERROR"
			
			var res : [Int32] = []
			for file in notSortedFiles {
				res.append(file.isDownloading)
			}
			add_torrent_with_states(urlRes.path, UnsafeMutablePointer(mutating: res))
			Manager.managerSaves[hash] = UserManagerSettings()
		} catch {
			let controller = ThemedUIAlertController(title: NSLocalizedString("Error has been occured", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
			let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
			controller.addAction(close)
			present(controller, animated: true)
		}
    }
	
	func updateWeightLabel() {
		var weight : Int64 = 0
		for file in notSortedFiles {
			if (file.isDownloading != 0) {
				weight += file.size
			}
		}
		weightLabel.title = Utils.getSizeText(size: weight)
	}
}

extension AddTorrentController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showFolders.keys.count + showFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row < showFolders.keys.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderCell
            let key = showFolders.keys.sorted()[indexPath.row]
            cell.title.text = key
            cell.size.text = Utils.getSizeText(size: showFolders[key]!.size)
            cell.actionDelegate = self
            return cell
        } else {
            let index = indexPath.row - showFolders.keys.count
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
            cell.file = showFiles[index]
            cell.index = index
            cell.adding = true
            cell.update()
            cell.switcher.setOn(showFiles[index].isDownloading != 0, animated: false)
            if (showFiles[index].size != 0 && showFiles[index].size == showFiles[index].downloaded) {
                cell.switcher.isEnabled = false
            }
            cell.actionDelegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.row < showFolders.count ) {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let title = NSLocalizedString("Priority", comment: "")
        let button = UITableViewRowAction(style: .default, title: title) { action, indexPath in
            let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Priority", comment: ""), preferredStyle: .actionSheet)
            
            // "Normal"
            let max = UIAlertAction(title: NSLocalizedString("High", comment: ""), style: .default, handler: { _ in
                let index = indexPath.row - self.showFolders.count
                self.showFiles[index].isDownloading = 4
                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
                
                self.updateWeightLabel()
            })
            let high = UIAlertAction(title: NSLocalizedString("Medium", comment: ""), style: .default, handler: { _ in
                let index = indexPath.row - self.showFolders.count
                self.showFiles[index].isDownloading = 3
                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
                
                self.updateWeightLabel()
            })
            let norm = UIAlertAction(title: NSLocalizedString("Low", comment: ""), style: .default, handler: { _ in
                let index = indexPath.row - self.showFolders.count
                self.showFiles[index].isDownloading = 2
                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
                
                self.updateWeightLabel()
            })
//            let min = UIAlertAction(title: NSLocalizedString("Low", comment: ""), style: .default, handler: { _ in
//                let index = indexPath.row - self.showFolders.count
//                self.showFiles[indexPath.row - self.showFolders.count].isDownloading = 1
//                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
//                set_torrent_file_priority(self.managerHash, Int32(self.showFiles[index].number), 1)
//            })
            
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            
            controller.addAction(max)
            controller.addAction(high)
            controller.addAction(norm)
            //            controller.addAction(min)
            controller.addAction(cancel)
            
            if (controller.popoverPresentationController != nil) {
                controller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                controller.popoverPresentationController?.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
                controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            }
            
            self.present(controller, animated: true)
        }
        button.backgroundColor = #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)
        (tableView.cellForRow(at: indexPath) as? FileCell)?.update()
        return [button]
    }
}

extension AddTorrentController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row < showFolders.keys.count) {
            let controller = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrentView") as! AddTorrentController
            controller.path = path
            controller.root = root + "/" + showFolders.keys.sorted()[indexPath.row]
            controller.navigationItem.setLeftBarButton(nil, animated: false)
            controller.notSortedFiles = notSortedFiles
            controller.files = files
            show(controller, sender: self)
        } else {
            let index = indexPath.row - showFolders.keys.count
            if (showFiles[index].size != 0 && showFiles[index].size == showFiles[index].downloaded) {
                return
            }
            let cell = tableView.cellForRow(at: indexPath) as! FileCell
            cell.switcher.setOn(!cell.switcher.isOn, animated: true)
            if (cell.actionDelegate != nil) {
                cell.actionDelegate?.fileCellAction(cell.switcher, index: index)
            }
        }
    }
}

extension AddTorrentController: FolderCellActionDelegate {
    func folderCellAction(_ key: String, sender: UIButton) {
        let controller = ThemedUIAlertController(title: NSLocalizedString("Download content of folder", comment: ""), message: key, preferredStyle: .actionSheet)
        
        let download = UIAlertAction(title: NSLocalizedString("Download", comment: ""), style: .default) { alert in
            for i in self.showFolders[key]!.files {
                i.isDownloading = 4
            }
            self.updateWeightLabel()
        }
        let notDownload = UIAlertAction(title: NSLocalizedString("Don't Download", comment: ""), style: .destructive) { alert in
            for i in self.showFolders[key]!.files {
                if (i.size != 0 && i.size == i.downloaded) {
                    i.isDownloading = 4
                } else {
                    i.isDownloading = 0
                }
            }
            self.updateWeightLabel()
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
        
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
}

extension AddTorrentController: FileCellActionDelegate {
    func fileCellAction(_ sender: UISwitch, index: Int) {
        showFiles[index].isDownloading = sender.isOn ? 4 : 0
        updateWeightLabel()
    }
}
