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
        var preview: TorrentSession.AddPreview
        var rootDirectory: PathNode?
        var completion: ((Bool) -> Void)?
    }
}

class TorrentAddViewModel: BaseViewModelWith<TorrentAddViewModel.Config> {
    private var preview: TorrentSession.AddPreview!
    private var rootDirectory: PathNode!
    private var keys: [String]!
    private(set) var isRoot: Bool = false
    private var completion: ((Bool) -> Void)?

    let updatePublisher = CurrentValueRelay<Void>(())
    let downloadStorage = CurrentValueRelay<UUID?>(nil)
    let downloadStorages = CurrentValueRelay<[TorrentSession.Storage]>([])

    override func prepare(with model: Config) {
        preview = model.preview
        isRoot = model.rootDirectory == nil
        rootDirectory = model.rootDirectory ?? generateRoot()
        completion = model.completion
        downloadStorage.value = preferences.defaultStorage

        keys = rootDirectory.makeKeys()
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
        .init(with: (preview, index, { [unowned self] in
            updatePublisher.send()
        }))
    }

    func pathModel(for path: PathNode) -> TorrentAddDirectoryItemViewModel {
        .init(with: (preview, path, path.name, { [unowned self] in
            updatePublisher.send()
        }))
    }

    func select(at index: Int) -> Bool {
        switch rootDirectory.storage[keys[index]] {
        case let path as PathNode:
            navigate(to: TorrentAddViewModel.self, with: .init(preview: preview, rootDirectory: path, completion: completion), by: .show)
            return false
        default:
            return true
        }
    }

    func cancel() {
        completion?(false)
        dismiss()
    }

    func download() {
        TorrentService.shared.addTorrent(preview.source, at: downloadStorage.value)
        completion?(true)
        dismiss()
    }

    func setAllFilesPriority(_ priority: FileEntry.Priority) {
        preview.setAllFilesPriority(priority)
        updatePublisher.send()
    }

    var diskTextPublisher: AnyPublisher<String, Never> {
        updatePublisher.map { [unowned self] _ in
            var selected: UInt64 = 0
            var total: UInt64 = 0
            preview.files.forEach { file in
                total += file.size
                if file.priority != .dontDownload {
                    selected += file.size
                }
            }
            return "\(selected.bitrateToHumanReadable) / \(total.bitrateToHumanReadable)"
        }.eraseToAnyPublisher()
    }

    var storages: [(name: String, selected: Bool, uuid: UUID?, allowed: Bool)] {
        [(TorrentSession.Storage.defaultName, downloadStorage.value == nil, nil, true)] +
        preferences.storageScopes.values.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
            .map { ($0.name, downloadStorage.value == $0.uuid, $0.uuid, $0.allowed ) }
    }
}

private extension TorrentAddViewModel {
    func generateRoot() -> PathNode {
        var root: PathNode = .init(name: preview.name)

        preview.files.forEach { file in
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

        guard let preview = TorrentSession.AddPreview(torrentFileURL: url)
        else { return }

        present(with: preview, from: navigationContext)
    }

    static func present(with preview: TorrentSession.AddPreview, from navigationContext: NavigationProtocol) {
        guard !presentAlert(from: navigationContext, ifTorrentExists: preview) else { return }
        Task { await navigationContext.navigate(to: TorrentAddViewModel(with: .init(preview: preview)).resolveVC(), by: .present(wrapInNavigation: true)) }
    }

    private static func presentAlert(from navigationContext: NavigationProtocol, ifTorrentExists preview: TorrentSession.AddPreview) -> Bool {
        guard TorrentService.shared.checkTorrentExists(with: preview.infoHashes)
        else { return false }

        let alert = UIAlertController(title: %"addTorrent.exists", message: %"addTorrent.\(preview.infoHashes.best.hex)_exists", preferredStyle: .alert)
        alert.addAction(.init(title: %"common.close", style: .cancel), isPrimary: true)
        navigationContext.present(alert, animated: true)
        return true
    }
}
