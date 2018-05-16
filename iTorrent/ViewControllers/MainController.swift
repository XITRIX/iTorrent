//
//  ViewController.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class MainController: UIViewController, UITableViewDataSource, UITableViewDelegate, ManagersUpdatedDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var managers : [TorrentStatus] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 104
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        Manager.managersUpdatedDelegates.append(self)
        managerUpdated()
    
        navigationController?.isToolbarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Manager.managersUpdatedDelegates = Manager.managersUpdatedDelegates.filter({$0 !== (self as ManagersUpdatedDelegate)})
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func managerUpdated() {
        let count = managers.count
        managers.removeAll()
        managers.append(contentsOf: Manager.torrentStates)
        if (count != managers.count) {
            tableView.reloadData()
        } else {
            for cell in tableView.visibleCells {
                (cell as! TorrentCell).manager = managers[(cell as! TorrentCell).indexPath.row]
                (cell as! TorrentCell).update()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return managers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TorrentCell
        cell.manager = managers[indexPath.row]
        cell.indexPath = indexPath
        cell.update()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Detail") as! TorrentDetailsController
        viewController.managerHash = managers[indexPath.row].hash
        
        if (!(splitViewController?.isCollapsed)!) {
//            if (splitViewController?.viewControllers.count)! > 1, let nav = splitViewController?.viewControllers[1] as? UINavigationController {
//                if let fileController = nav.topViewController
//            }
            let navController = UINavigationController(rootViewController: viewController)
            navController.isToolbarHidden = false
            navController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
            navController.toolbar.tintColor = navigationController?.navigationBar.tintColor
            splitViewController?.showDetailViewController(navController, sender: self)
        } else {
            splitViewController?.showDetailViewController(viewController, sender: self)
        }
    }
    
    @IBAction func AddTorrentAction(_ sender: UIBarButtonItem) {
        let addController = UIAlertController(title: "Add from...", message: nil, preferredStyle: .actionSheet)
        
        let addURL = UIAlertAction(title: "URL", style: .default) { _ in
            let addURLController = UIAlertController(title: "Add from URL", message: "Please enter the existing torrent's URL below", preferredStyle: .alert)
            addURLController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "https://"
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addURLController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
                
                Downloader.load(url: URL(string: textField.text!)!, to: URL(fileURLWithPath: Manager.configFolder+"/_temp.torrent"), completion: {
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
                    ((controller as! UINavigationController).topViewController as! AddTorrentController).path = Manager.configFolder+"/_temp.torrent"
                    self.present(controller, animated: true)
                    //Manager.addTorrent(Manager.configFolder+"/_temp.torrent")
                })
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            addURLController.addAction(ok)
            addURLController.addAction(cancel)
            
            self.present(addURLController, animated: true)
        }
        let addMagnet = UIAlertAction(title: "Magnet", style: .default) { _ in
            let addMagnetController = UIAlertController(title: "Add from magnet", message: "Please enter the magnet link below", preferredStyle: .alert)
            addMagnetController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "magnet:"
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addMagnetController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
                
                Manager.addMagnet(textField.text!)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            addMagnetController.addAction(ok)
            addMagnetController.addAction(cancel)
            
            self.present(addMagnetController, animated: true)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        addController.addAction(addMagnet)
        addController.addAction(addURL)
        addController.addAction(cancel)
        
        present(addController, animated: true)
    }
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
        tableView.reloadData()
    }
    
}

