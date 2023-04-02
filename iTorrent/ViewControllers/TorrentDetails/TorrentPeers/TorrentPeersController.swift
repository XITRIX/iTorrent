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
    private let managerHash: String
    private var peers: [PeerModel] = []

    init(hash: String) {
        managerHash = hash
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.allowsSelection = false
        peers = TorrentSdk.getPeers(with: managerHash)
        tableView.reloadData()
        title = "Details.More.Peers".localized
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
                if res.inserts.count > 0 { tableView.insertRows(at: res.inserts, with: .top) }
                if res.deletes.count > 0 { tableView.deleteRows(at: res.deletes, with: .top) }
            }, completion: nil)
        }

        reloadVisibleCells()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        peers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PeerCell.id, for: indexPath) as! PeerCell
        cell.setModel(peers[indexPath.row])
        return cell
    }

    func reloadVisibleCells() {
        tableView.visibleCells.forEach { cell in
            guard let indexPath = tableView.indexPath(for: cell),
                  let peerCell = cell as? PeerCell
            else { return }

            let item = peers[indexPath.row]
            peerCell.setModel(item)
        }
    }
}
