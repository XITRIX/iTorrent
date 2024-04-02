//
//  BasePreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/04/2024.
//

import MvvmFoundation

class BasePreferencesViewModel: BaseViewModel {
    let sections = CurrentValueRelay<[MvvmCollectionSectionModel]>([])
    let dismissSelection = PassthroughRelay<Void>()
    let title = CurrentValueRelay<String>("")
}
