//
//  SettingsSortingController.swift
//  iTorrent
//
//  Created by  XITRIX on 19.06.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SettingsSortingController: ThemedUITableViewController {
    var data: [Int]!
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        data = UserPreferences.sectionsSortingOrder.value
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        tableView.dataSource = self
        tableView.delegate = self

        tableView.tableFooterView = UIView()

        tableView.isEditing = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UserPreferences.sectionsSortingOrder.value = data
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

extension SettingsSortingController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = NSLocalizedString(Utils.TorrentStates.init(id: data[indexPath.row])?.rawValue ?? "NIL", comment: "")

        let theme = Themes.current
        cell.textLabel?.textColor = theme.mainText
        cell.backgroundColor = theme.backgroundMain

        return cell
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = data[sourceIndexPath.row]
        data.remove(at: sourceIndexPath.row)
        data.insert(itemToMove, at: destinationIndexPath.row)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
}
