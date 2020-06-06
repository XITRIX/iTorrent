//
//  TorrentListViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class TorrentListViewModel: ViewModel {
    var tableViewData = Box<[SectionModel<TorrentModel>]>([])
    var searchFilter = Box<String?>("")
    var tableviewPlaceholderHidden = Box<Bool>(true)
    var loadingIndicatiorHidden = Box<Bool>(true)
    
    override func viewWillAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .mainLoopTick, object: nil)
        update()
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func update(animated: Bool = true) {
        if Core.shared.state == .Initializing { return }
        else { loadingIndicatiorHidden.variable = true }
        
        let searchFiltered = Array(Core.shared.torrents.values).filter { self.searchFilter($0, filter: searchFilter.variable) }
        tableViewData.variable = SortingManager.sort(managers: searchFiltered)
        
        tableviewPlaceholderHidden.variable = tableViewData.variable.contains(where: { $0.items.count > 0 })
    }
    
    func searchFilter(_ model: TorrentModel, filter: String?) -> Bool {
        if let filter = filter {
            let separatedQuery = filter.lowercased().split {
                $0 == " " || $0 == ","
            }
            return separatedQuery.allSatisfy { model.title.lowercased().contains($0) }
        }
        return true
    }
}
