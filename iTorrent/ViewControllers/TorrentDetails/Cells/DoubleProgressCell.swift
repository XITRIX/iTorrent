//
//  DoubleProgressCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class DoubleProgressCell: ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "DoubleProgressCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    static let name = id

    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var topProgressBar: SegmentedProgressView!
    @IBOutlet var bottomProgressBar: SegmentedProgressView!

    private var torrentModel: TorrentModel!
    private var sortedFilesData: [FilePieceData]!

    func setupPiecesFilter() {
        if sortedFilesData != nil {
            return
        }
        sortedFilesData = TorrentSdk.getFilesOfTorrentByHash(hash: torrentModel.hash)!
            .sorted(by: { $0.name < $1.name })
            .map { FilePieceData(name: $0.name, beginIdx: $0.beginIdx, endIdx: $0.endIdx) }
    }

    func sortPiecesByFilesName(_ pieces: [Int]) -> [CGFloat] {
        var res: [CGFloat] = []

        for file in sortedFilesData {
            for piece in file.beginIdx...file.endIdx {
                res.append(CGFloat(pieces[Int(piece)]))
            }
        }

        return res
    }

    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        title?.text = Localize.get(model.title)
        torrentModel = model.torrentModel()

        if torrentModel.hasMetadata {
            setupPiecesFilter()
            
            let totalDownloadProgress = torrentModel.totalSize > 0 ? Float(torrentModel.totalDone) / Float(torrentModel.totalSize) : 0
            bottomProgressBar.setProgress([totalDownloadProgress])
            // Very large torrents cause "ladder" effect (lags) while scrolling on running in main thread
            DispatchQueue.global(qos: .background).async {
                let pieces = self.sortPiecesByFilesName(self.torrentModel.pieces)
                DispatchQueue.main.async {
                    self.topProgressBar.setProgress(pieces)
                }
            }
        }
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var torrentModel: () -> TorrentModel?
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?
        var longPressAction: (() -> ())?
    }
}
