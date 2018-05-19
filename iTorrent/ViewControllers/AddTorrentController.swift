//
//  AddTorrentController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class AddTorrentController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var path : String!
    
    var name : String = ""
    var fileNames : [String] = []
    var fileSizes : [Int64] = []
    var fileSelectes : [Int32] = []
    var sortMask : [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let files = get_files_of_torrent_by_path(path)
        
        name = String(validatingUTF8: files.title) ?? "ERROR"
        let size = Int(files.size)
        let namesArr = Array(UnsafeBufferPointer(start: files.file_name, count: size))
        let sizesArr = Array(UnsafeBufferPointer(start: files.file_size, count: size))
        
        for i in 0 ..< size {
            fileNames.append(String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR")
            fileSizes.append(sizesArr[i])
            fileSelectes.append(4)
        }
        
        let sort = fileNames.sorted()
        for i in 0 ..< sort.count {
            sortMask.append(fileNames.index(of: sort[i])!)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 78
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
        cell.title.text = fileNames[sortMask[indexPath.row]]
        cell.size.text = Utils.getSizeText(size: fileSizes[sortMask[indexPath.row]])
		cell.switcher.setOn(fileSelectes[sortMask[indexPath.row]] != 0, animated: false)
        cell.action = { switcher in
			self.fileSelectes[self.sortMask[indexPath.row]] = switcher.isOn ? 4 : 0
        }
        return cell
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        if (FileManager.default.fileExists(atPath: Manager.configFolder+"/_temp.torrent")) {
            try! FileManager.default.removeItem(atPath: Manager.configFolder+"/_temp.torrent")
        }
        dismiss(animated: true)
    }
	
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
			(cell as! FileCell).switcher.setOn(false, animated: true)
		}
		for i in 0 ..< fileSelectes.count {
			fileSelectes[i] = 0
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
	
    @IBAction func downloadAction(_ sender: UIBarButtonItem) {
        let urlPath = URL(fileURLWithPath: path)
        let urlRes = urlPath.deletingLastPathComponent().appendingPathComponent(name+".torrent")
		if (FileManager.default.fileExists(atPath: urlRes.path)) {
			try! FileManager.default.removeItem(at: urlRes)
		}
        try! FileManager.default.copyItem(at: urlPath, to: urlRes)
        if (path.hasSuffix("_temp.torrent")) {
            try! FileManager.default.removeItem(atPath: Manager.configFolder+"/_temp.torrent")
        }
        dismiss(animated: true)
        add_torrent_with_states(urlRes.path, UnsafeMutablePointer(mutating: fileSelectes))
    }
}
