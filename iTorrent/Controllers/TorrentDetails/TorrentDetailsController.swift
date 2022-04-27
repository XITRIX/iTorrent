//
//  TorrentDetailsController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import MarqueeLabel
import MVVMFoundation
import UIKit

class TorrentDetailsController: MvvmTableViewController<TorrentDetailsViewModel> {
    var dataSource: DiffableDataSource<TableCellRepresentable>!

    let playItem = UIBarButtonItem(barButtonSystemItem: .play, target: nil, action: nil)
    let pauseItem = UIBarButtonItem(barButtonSystemItem: .pause, target: nil, action: nil)
    let rehashItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
    let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
    let shareItem = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
    let spacerItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    var marqueeTitle: MarqueeLabel!
    lazy var torrentControls: [UIBarButtonItem] = [playItem, spacerItem, pauseItem, spacerItem, rehashItem, spacerItem, spacerItem, spacerItem, spacerItem, spacerItem, removeItem]

    deinit {
        print("Deinit!")
    }

    override func setupView() {
        super.setupView()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonTitle = "Back"
        toolbarItems = torrentControls
        navigationItem.setRightBarButton(shareItem, animated: false)

        setupShareItem()
        setupMarqueeTitle()

        viewModel.sections.flatMap { $0.items }.forEach { $0.registerCell(in: tableView) }
        dataSource = DiffableDataSource<TableCellRepresentable>.init(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            itemIdentifier.resolveCell(in: tableView, for: indexPath)
        })
        tableView.dataSource = dataSource
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func binding() {
        super.binding()
        bind(in: bag) {
            viewModel.title => marqueeTitle
            playItem.bindTap(viewModel.resume)
            pauseItem.bindTap(viewModel.pause)
            viewModel.canResume => playItem.reactive.isEnabled
            viewModel.canPause => pauseItem.reactive.isEnabled
            rehashItem.bindTap { [unowned self] in rehashAction() }
            removeItem.bindTap { [unowned self] in removeAction() }

            viewModel.$sections.observeNext { [unowned self] values in
                var snapshot = DiffableDataSource<TableCellRepresentable>.Snapshot()
                snapshot.append(values)
                dataSource.apply(snapshot)
            }

            tableView.reactive.selectedRowIndexPath.observeNext { [unowned self] indexPath in
                viewModel.sections[indexPath.section].items[indexPath.row].action.send()
            }
        }
    }

    func rehashAction() {
        let alert = UIAlertController(title: "Torrent rehash?", message: "This action will recheck the state of all downloaded files", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Rehash", style: .destructive, handler: { [unowned self] _ in viewModel.rehash() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func removeAction() {
        let alert = UIAlertController(title: "Are you shure to remove?", message: title, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes and remove files", style: .destructive, handler: { [unowned self] _ in viewModel.removeTorrent(withFiles: true) }))
        alert.addAction(UIAlertAction(title: "Yes but keep files", style: .default, handler: { [unowned self] _ in viewModel.removeTorrent(withFiles: false) }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func setupShareItem() {
        let fileAction = UIAction(title: "Torrent file", image: UIImage(systemName: "doc.text"), handler: { [unowned self] _ in
            guard let stringPath = viewModel.torrentFilePath
            else { return }

            let path = NSURL(fileURLWithPath: stringPath, isDirectory: false)
            let shareController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            if shareController.popoverPresentationController != nil {
                shareController.popoverPresentationController?.barButtonItem = shareItem
                shareController.popoverPresentationController?.permittedArrowDirections = .any
            }
            present(shareController, animated: true)

        })

        let magnetAction = UIAction(title: "Magnet link", image: UIImage(systemName: "link"), handler: { [unowned self] _ in
            UIPasteboard.general.string = viewModel.torrentMagnetLink
            Dialog.withTimer(self, message: "Magnet link copied to clipboard")
        })

        var actions = [UIAction]()
        if viewModel.torrentFilePath != nil { actions.append(fileAction) }
        actions.append(magnetAction)

        let menu = UIMenu(title: "Share", options: [], children: actions)

        shareItem.menu = menu
    }

    func setupMarqueeTitle() {
        marqueeTitle = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
        marqueeTitle.font = UIFont.boldSystemFont(ofSize: 17)
        marqueeTitle.textAlignment = NSTextAlignment.center
        marqueeTitle.trailingBuffer = 44
        navigationItem.titleView = marqueeTitle
    }
}
