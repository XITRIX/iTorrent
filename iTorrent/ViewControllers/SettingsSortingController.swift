//
//  SettingsSortingController.swift
//  iTorrent
//
//  Created by  XITRIX on 19.06.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SettingsSortingController : ThemedUIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var data : [Int]!
    
    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current().backgroundMain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data = UserDefaults.standard.value(forKey: UserDefaultsKeys.sectionsSortingOrder) as? [Int] {
            self.data = data
        }
//        else {
//            for s in Utils.torrentStates.allCases {
//                self.data.append(s.rawValue)
//            }
//        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableFooterView = UIView()
        
        tableView.isEditing = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UserDefaults.standard.set(data, forKey: UserDefaultsKeys.sectionsSortingOrder)
    }
    
    @IBAction func revertAction(_ sender: UIBarButtonItem) {
        data = [3,
                7,
                8,
                6,
                2,
                4,
                5,
                9,
                1]
        
        tableView.reloadData()
    }
}

extension SettingsSortingController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = NSLocalizedString(Utils.torrentStates.init(id: data[indexPath.row])?.rawValue ?? "NIL", comment: "")
        
        let theme = Themes.current()
        cell.textLabel?.textColor = theme.mainText
        cell.backgroundColor = theme.backgroundMain
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = data[sourceIndexPath.row]
        data.remove(at: sourceIndexPath.row)
        data.insert(itemToMove, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
}
