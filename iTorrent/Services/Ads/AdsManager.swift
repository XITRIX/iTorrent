//
//  AdsManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2024.
//

import MvvmFoundation

@MainActor
class AdsManager {
    init() {
        Mvvm.shared.container.registerDaemon(factory: UnityAdsManager.init)
        Mvvm.shared.container.registerDaemon(factory: GoogleAdsManager.init)
        Mvvm.shared.container.registerDaemon(factory: MetaAdsManager.init)
    }
}
