//
//  TorrentListViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import Foundation

class TorrentListViewModel: ViewModel {
    var tableViewData = Box<[SectionModel<TorrentModel>]>([])
    var searchFilter = Box<String?>("")
    var stateFilter = Box<TorrentState>(.null)
    var tableviewPlaceholderHidden = Box<Bool>(true)
    var loadingIndicatiorHidden = Box<Bool>(false)
    
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
        
        var data = Array(Core.shared.torrents.values)
        if !UserPreferences.sortingSections {
            data = data.filter { stateFilter.variable == .null || $0.displayState == stateFilter.variable }
        }
        data = data.filter { self.searchFilter($0, filter: searchFilter.variable) }
        tableViewData.variable = SortingManager.sort(managers: data)
        
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
