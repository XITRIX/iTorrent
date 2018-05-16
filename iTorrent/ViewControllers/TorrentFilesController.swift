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
    var fileNames : [String] = []
    var fileSizes : [Int64] = []
    var fileSelectes : [Int32] = []
    var sortMask : [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let files = get_files_of_torrent_by_hash(managerHash)
        if files.error == 1 {
            dismiss(animated: false)
            return
        }
        
        name = String(validatingUTF8: files.title) ?? "ERROR"
        let size = Int(files.size)
        let namesArr = Array(UnsafeBufferPointer(start: files.file_name, count: size))
        let sizesArr = Array(UnsafeBufferPointer(start: files.file_size, count: size))
        
        for i in 0 ..< size {
            fileNames.append(String(validatingUTF8: namesArr[Int(i)]!) ?? "ERROR")
            fileSizes.append(sizesArr[i])
            fileSelectes.append(files.file_priority[i])
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: fileSelectes))
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
            print("set " + String(self.fileSelectes[self.sortMask[indexPath.row]]))
        }
        return cell
    }
    
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
    }
    @IBAction func SelectAction(_ sender: UIBarButtonItem) {
    }
}
