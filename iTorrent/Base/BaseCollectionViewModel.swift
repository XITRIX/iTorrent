//
//  BaseCollectionViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Foundation
import MvvmFoundation
import UIKit

open class BaseCollectionViewModel: BaseViewModel {
    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var selectedIndexPaths: [IndexPath] = []
    @Published var refreshTask: (() async -> Void)? = nil
    @Published var trailingSwipeActionsConfigurationProvider: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider?

    let dismissSelection = PassthroughRelay<Void>()
}

open class BaseCollectionViewModelWith<Model>: BaseCollectionViewModel, MvvmViewModelWithProtocol {
    open func prepare(with model: Model) { /* Override and use instead of `init` to prepare ViewModel */ }
}
