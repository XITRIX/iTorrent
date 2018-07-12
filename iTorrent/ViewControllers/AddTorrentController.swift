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
	
	var files : [File] = []
	var notSortedFiles : [File] = []
	
	var showFolders : [String:Folder] = [:]
	var showFiles : [File] = []
	
	var root : String = ""
	
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
        
		if (root.starts(with: "/")) { root.removeFirst() }
		
		if (root == "") {
			let back = UIBarButtonItem()
			back.title = "Back"
			navigationItem.backBarButtonItem = back
			
			initialize()
		} else {
			let urlRoot = URL(string: root.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)
			title = urlRoot?.lastPathComponent
			
			let titleView = FileManagerTitleView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
			titleView.title.text = title
			titleView.subTitle.text = urlRoot?.deletingLastPathComponent().path
			titleView.updateTheme()
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
    }
	
	func initialize() {
		let localFiles = get_files_of_torrent_by_path(path)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
		
		name = String(validatingUTF8: localFiles.title) ?? "ERROR"
		let size = Int(localFiles.size)
		let namesArr = Array(UnsafeBufferPointer(start: localFiles.file_name, count: size))
		let sizesArr = Array(UnsafeBufferPointer(start: localFiles.file_size, count: size))
		
		for i in 0 ..< size {
			let file = File()
			
			let n = String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR"
			let name = URL(string: n.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
			file.name = name.lastPathComponent
			file.path = name.deletingLastPathComponent().path == "." ? "" : name.deletingLastPathComponent().path
			file.size = sizesArr[i]
			file.isDownloading = true
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
			cell.updateTheme()
			return cell
		} else {
			let index = indexPath.row - showFolders.keys.count
			let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
			cell.file = showFiles[index]
			cell.index = index
			cell.update()
			cell.switcher.setOn(showFiles[index].isDownloading, animated: false)
			cell.actionDelegate = self
			cell.updateTheme()
			return cell
		}
    }
	
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
			for i in self.showFolders[key]!.files {
				i.isDownloading = true
			}
		}
		let notDownload = UIAlertAction(title: "Don't Download", style: .destructive) { alert in
			for i in self.showFolders[key]!.files {
				i.isDownloading = false
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
		showFiles[index].isDownloading = sender.isOn
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
		for i in 0 ..< files.count {
			files[i].isDownloading = false
		}
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
			if let cell = cell as? FileCell {
				cell.switcher.setOn(true, animated: true)
			}
		}
		for i in 0 ..< files.count {
			files[i].isDownloading = true
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
			
			var res : [Int32] = []
			for file in notSortedFiles {
				res.append(file.isDownloading ? 4 : 0)
			}
			add_torrent_with_states(urlRes.path, UnsafeMutablePointer(mutating: res))
			Manager.managerSaves[hash] = UserManagerSettings()
		} catch {
			let controller = ThemedUIAlertController(title: "Error has been occured", message: error.localizedDescription, preferredStyle: .alert)
			let close = UIAlertAction(title: "Close", style: .cancel)
			controller.addAction(close)
			present(controller, animated: true)
		}
    }
}
