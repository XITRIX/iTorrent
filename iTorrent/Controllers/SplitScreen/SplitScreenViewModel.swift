//
//  SplitControllerViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 03.05.2022.
//

import MVVMFoundation

class SplitScreenViewModel: MvvmViewModel, MvvmSplitViewModelProtocol {
    var primaryViewModel: (model: MvvmViewModel.Type, wrappedInNavigation: Bool) { (TorrentsListViewModel.self, true) }
    var secondaryViewModel: (model: MvvmViewModel.Type, wrappedInNavigation: Bool)? { nil }
}
