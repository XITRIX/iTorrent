//
//  TorrentPeersController.swift
//
//
//  Created by Daniil Vinogradov on 28.06.2020.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import DeepDiff
import UIKit

class TorrentPeersController: ThemedUITableViewController {
    var managerHash: String!
    var peers: [PeerModel] = []

    override var toolBarIsHidden: Bool? {
        true
    }

    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PeerCell.nib, forCellReuseIdentifier: PeerCell.id)
        peers = TorrentSdk.getPeers(with: managerHash)
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .mainLoopTick, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .mainLoopTick, object: nil)
    }

    @objc func update() {
        let peersNew = TorrentSdk.getPeers(with: managerHash)
        let changes = diff(old: peers, new: peersNew)
        peers = peersNew

        let res = IndexPathConverter().convert(changes: changes, section: 0)

        if changes.count > 0 {
            tableView.unifiedPerformBatchUpdates({
                if res.inserts.count > 0 { tableView.insertRows(at: res.inserts, with: .fade) }
                if res.deletes.count > 0 { tableView.deleteRows(at: res.deletes, with: .fade) }
            }, completion: nil)
        }

        res.replaces.forEach { indexPath in
            if let cell = tableView.cellForRow(at: indexPath) as? PeerCell {
                cell.setModel(peersNew[indexPath.row])
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        peers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PeerCell.id, for: indexPath) as! PeerCell
        cell.setModel(peers[indexPath.row])
        return cell
    }
}
