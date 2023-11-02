//
//  TorrentFilesItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01/11/2023.
//

import MvvmFoundation
import LibTorrent

class TorrentFilesItemViewModel: BaseViewModelWith<FileEntry>, ObservableObject {
    @Published var file: FileEntry!
    
    override func prepare(with model: FileEntry) {
        file = model
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(file.name)
        hasher.combine(file.path)
    }
}
