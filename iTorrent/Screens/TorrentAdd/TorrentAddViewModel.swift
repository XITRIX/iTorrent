//
//  TorrentAddViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import UIKit

extension TorrentAddViewModel {
    struct Config {
        var torrentFile: TorrentFile
        var rootDirectory: PathNode?
        var completion: ((Bool) -> Void)?
    }
}

class TorrentAddViewModel: BaseViewModelWith<TorrentAddViewModel.Config> {
    private var torrentFile: TorrentFile!
    private var rootDirectory: PathNode!
    private var keys: [String]!
    private(set) var isRoot: Bool = false
    private var completion: ((Bool) -> Void)?

    let updatePublisher = CurrentValueRelay<Void>(())
    let downloadStorage = CurrentValueRelay<UUID?>(nil)
    let downloadStorages = CurrentValueRelay<[StorageModel]>([])

    override func prepare(with model: Config) {
        torrentFile = model.torrentFile
        isRoot = model.rootDirectory == nil
        rootDirectory = model.rootDirectory ?? generateRoot()
        completion = model.completion
        downloadStorage.value = preferences.defaultStorage

        keys = rootDirectory.storage
            .sorted(by: { first, second in
                let f = first.value.name
                let s = second.value.name
                return f.localizedCaseInsensitiveCompare(s) == .orderedAscending
            })
            .sorted(by: { first, second in
                if !first.key.starts(with: "./"), !second.key.starts(with: "./") {
                    let f = first.value.name
                    let s = second.value.name
                    return f.localizedCaseInsensitiveCompare(s) == .orderedAscending
                }
                return !first.key.starts(with: "./")
            })
            .map { $0.key }
    }

    override func willAppear() {
        updatePublisher.send()
    }

    @Injected private var preferences: PreferencesStorage
}

extension TorrentAddViewModel {
    var title: String {
        rootDirectory.name
    }

    var filesCount: Int {
        keys.count
    }

    func node(at index: Int) -> Node {
        rootDirectory.storage[keys[index]]!
    }

    func fileModel(for index: Int) -> TorrentAddFileItemViewModel {
        .init(with: (torrentFile, index, { [unowned self] in
            updatePublisher.send()
        }))
    }

    func pathModel(for path: PathNode) -> TorrentAddDirectoryItemViewModel {
        .init(with: (torrentFile, path, path.name, { [unowned self] in
            updatePublisher.send()
        }))
    }

    @MainActor
    func select(at index: Int) -> Bool {
        switch rootDirectory.storage[keys[index]] {
        case let path as PathNode:
            navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: torrentFile, rootDirectory: path, completion: completion), by: .show)
            return false
        default:
            return true
        }
    }

    @MainActor
    func cancel() {
        completion?(false)
        dismiss()
    }

    @MainActor
    func download() {
        TorrentService.shared.addTorrent(by: torrentFile, at: downloadStorage.value)
        completion?(true)
        dismiss()
    }

    func setAllFilesPriority(_ priority: FileEntry.Priority) {
        torrentFile.setAllFilesPriority(priority)
        updatePublisher.send()
    }

    var diskTextPublisher: AnyPublisher<String, Never> {
        updatePublisher.map { [unowned self] _ in
            var selected: UInt64 = 0
            var total: UInt64 = 0
            torrentFile.files.forEach { file in
                total += file.size
                if file.priority != .dontDownload {
                    selected += file.size
                }
            }
            return "\(selected.bitrateToHumanReadable) / \(total.bitrateToHumanReadable)"
        }.eraseToAnyPublisher()
    }

    var storages: [(name: String, selected: Bool, uuid: UUID?, allowed: Bool)] {
        [(StorageModel.defaultName, downloadStorage.value == nil, nil, true)] +
        preferences.storageScopes.values.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
            .map { ($0.name, downloadStorage.value == $0.uuid, $0.uuid, $0.allowed ) }
    }
}

private extension TorrentAddViewModel {
    func generateRoot() -> PathNode {
        var root: PathNode = .init(name: torrentFile.name)

        torrentFile.files.forEach { file in
            let pathComponents = file.path.components(separatedBy: "/")
            root.append(path: pathComponents, index: Int(file.index))
        }

        if let newRoot = root.storage.first?.value as? PathNode {
            root = newRoot
        }

//        root.name = "Files"
        return root
    }
}

extension TorrentAddViewModel {
    static func present(with url: URL, from navigationContext: NavigationProtocol) {
        // TODO: Check if URL root is not the same as Application document root
        defer { url.stopAccessingSecurityScopedResource() }
        _ = url.startAccessingSecurityScopedResource()

        guard let file = TorrentFile(with: url)
        else { return }

        Task { @MainActor in
            guard !presentAlert(from: navigationContext, ifTorrentExists: file) else { return }
            navigationContext.navigate(to: TorrentAddViewModel(with: .init(torrentFile: file)).resolveVC(), by: .present(wrapInNavigation: true))
        }
    }

    static func present(with torrentFile: TorrentFile, from navigationContext: NavigationProtocol) {
        Task { @MainActor in
            guard !presentAlert(from: navigationContext, ifTorrentExists: torrentFile) else { return }
            navigationContext.navigate(to: TorrentAddViewModel(with: .init(torrentFile: torrentFile)).resolveVC(), by: .present(wrapInNavigation: true))
        }
    }

    @MainActor
    private static func presentAlert(from navigationContext: NavigationProtocol, ifTorrentExists torrentFile: TorrentFile) -> Bool {
        guard TorrentService.shared.torrents[torrentFile.infoHashes] != nil
        else { return false }

        let alert = UIAlertController(title: %"addTorrent.exists", message: %"addTorrent.\(torrentFile.infoHashes.best.hex)_exists", preferredStyle: .alert)
        alert.addAction(.init(title: %"common.close", style: .cancel))
        navigationContext.present(alert, animated: true)
        return true
    }
}
