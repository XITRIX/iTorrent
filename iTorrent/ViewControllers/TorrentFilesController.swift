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
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		initialize()
		update()
		
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 78
        
        tableView.reloadData()
		
		DispatchQueue.global(qos: .background).async {
			while(true) {
				DispatchQueue.main.async {
					self.update()
				}
				sleep(1)
			}
		}
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: fileSelectes))
    }
	
	func initialize() {
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
		
		for i in 0 ..< localFiles.size {
			fileSelectes.append(localFiles.file_priority[Int(i)])
		}
	}
	
	func update() {
		files.removeAll()
		sortMask.removeAll()
		
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
			let file = FileInfo()
			file.fileName = String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR"
			file.filePath = String(validatingUTF8: pathsArr[Int(i)]!) ?? "ERROR"
			file.fileSize = sizesArr[i]
			file.fileDownloaded = localFiles.file_downloaded[i]
			files.append(file)
		}
		
		let sort = files.sorted(by: {$0.fileName < $1.fileName})
		for i in 0 ..< sort.count {
			sortMask.append(files.index(where: {$0.fileName == sort[i].fileName})!)
		}
		
		DispatchQueue.main.async {
			for cell in self.tableView.visibleCells {
				let cell = cell as! FileCell
				cell.file = self.files[self.sortMask[cell.indexPath.row]]
				cell.update()
			}
		}
	}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
		cell.file = files[sortMask[indexPath.row]]
		cell.name = name
		cell.indexPath = indexPath
		cell.update()
		cell.switcher.setOn(fileSelectes[sortMask[indexPath.row]] != 0, animated: false)
        cell.action = { switcher in
            self.fileSelectes[self.sortMask[indexPath.row]] = switcher.isOn ? 4 : 0
        }
        return cell
    }
    
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
			(cell as! FileCell).switcher.setOn(false, animated: true)
		}
		for i in 0 ..< fileSelectes.count {
			if (files[i].fileDownloaded / files[i].fileSize == 1) {
				fileSelectes[i] = 4
			} else {
				fileSelectes[i] = 0
			}
		}
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
			(cell as! FileCell).switcher.setOn(true, animated: true)
		}
		for i in 0 ..< fileSelectes.count {
			fileSelectes[i] = 4
		}
    }
}
