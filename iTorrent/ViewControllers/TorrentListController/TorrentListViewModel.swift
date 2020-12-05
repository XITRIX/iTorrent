//
//  TorrentListViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import Foundation
import Bond

class TorrentListViewModel: ViewModel {
    var tableViewData = MutableObservableArray<SectionModel<TorrentModel>>([])
    var searchFilter = Observable<String?>("")
    var stateFilter = Observable<TorrentState>(.null)
    var tableviewPlaceholderHidden = Observable<Bool>(true)
    var loadingIndicatiorHidden = Observable<Bool>(false)
    
    override func viewWillAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .mainLoopTick, object: nil)
        update()
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func update(animated: Bool = true) {
        if Core.shared.state.value == .Initializing { return }
        else { loadingIndicatiorHidden.value = true }
        
        var data = Array(Core.shared.torrents.values)
        if !UserPreferences.sortingSections {
            data = data.filter { stateFilter.value == .null || $0.displayState == stateFilter.value }
        }
        data = data.filter { self.searchFilter($0, filter: searchFilter.value) }
        tableViewData.replace(with: SortingManager.sort(managers: data))
        
        tableviewPlaceholderHidden.value = tableViewData.value.collection.contains(where: { $0.items.count > 0 })
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
