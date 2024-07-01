//
//  StoragePreferencesView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 03.07.2024.
//

import LibTorrent
import MvvmFoundation
import SwiftUI
import UniformTypeIdentifiers

class StoragePreferencesViewModel: BaseViewModel, ObservableObject {
    @Published var allocateMemory: Bool = false
    @Published var customStoragesVM: [UUID: StorageModel] = [:]
    @Published var currentStorage: UUID?
    @Published var isStorageRulesAccepted: Bool = false

    required init() {
        super.init()
        allocateMemory = preferences.allocateMemory
        preferences.$storageScopes.assign(to: &$customStoragesVM)

        isStorageRulesAccepted = preferences.isStorageRulesAccepted
        preferences.$isStorageRulesAccepted.assign(to: &$isStorageRulesAccepted)

        preferences.$defaultStorage.assign(to: &$currentStorage)

        disposeBag.bind {
            $allocateMemory.sink { [unowned self] in preferences.allocateMemory = $0 }
        }
    }

    @Injected var preferences: PreferencesStorage
}

struct StoragePreferencesView<VM: StoragePreferencesViewModel>: MvvmSwiftUIViewProtocol {
    @ObservedObject var viewModel: VM
    @State var filePickerPresented: Bool = false

    let storagesLimit = 5
    var title: String = %"preferences.storage"

    init(viewModel: VM) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            Section {
                Toggle("preferences.storage.allocate", isOn: $viewModel.allocateMemory)
            }

            if !viewModel.isStorageRulesAccepted {
                Section {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("preferences.storage.warning.title")
                                .fontWeight(.semibold)

                            Text("preferences.storage.warning.message")
                        }

                        Button {
                            withAnimation {
                                viewModel.preferences.isStorageRulesAccepted = true
                            }
                        } label: {
                            Spacer()
                            Text("preferences.storage.warning.accept")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .accentColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .listRowBackground(Color.red.opacity(0.1))
                .listRowSeparator(.hidden)
            }

            Section {
                Button {
                    viewModel.preferences.defaultStorage = nil
                } label: {
                    HStack {
                        Text(StorageModel.defaultName)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if viewModel.preferences.defaultStorage == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .fontWeight(.medium)
                        }
                    }
                }
                ForEach(Array(viewModel.customStoragesVM.values.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending }))) { scope in
                    Button {
                        if scope.allowed {
                            viewModel.preferences.defaultStorage = scope.uuid
                        }
                    } label: {
                        HStack {
                            Text(scope.name)
                                .foregroundStyle(scope.allowed ? Color.primary : Color.secondary)
                            Spacer()
                            if viewModel.preferences.defaultStorage == scope.uuid {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.medium)
                            } else if !scope.allowed {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }.swipeActions {
                        Button(role: .destructive) {
                            viewModel.preferences.storageScopes[scope.uuid] = nil
                            if viewModel.preferences.defaultStorage == scope.uuid {
                                viewModel.preferences.defaultStorage = nil
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                if viewModel.customStoragesVM.count < storagesLimit - 1 {
                    Button("preferences.storage.add") {
                        filePickerPresented = true
                    }.disabled(!viewModel.isStorageRulesAccepted)
                }
            } header: {
                HStack {
                    Text("preferences.storage.storages")
                    Spacer()
                    Text("preferences.storage.storages.available\(viewModel.customStoragesVM.count + 1)/\(storagesLimit)")
                }
            }
        }.fileImporter(isPresented: $filePickerPresented, allowedContentTypes: [.folder]) { result in
            guard let url = try? result.get() else { return }

            guard url.isDirectory else {
                return viewModel.alert(title: %"common.error", message: %"preferences.storage.add.error.notDirectory", actions: [
                    .init(title: %"common.close", style: .cancel)
                ])
            }

            let allowed = url.startAccessingSecurityScopedResource()
            print("Path - \(url) | write permissions - \(allowed)")

            guard let bookmark = try? url.bookmarkData(options: [.minimalBookmark])
            else { return }

            if let storage = viewModel.preferences.storageScopes.values.first(where: {
                $0.url == url || $0.url == TorrentService.downloadPath
            }) {
                storage.pathBookmark = bookmark
                return
            }

            let storage = StorageModel()
            storage.uuid = UUID()
            storage.name = url.lastPathComponent
            storage.url = url
            storage.allowed = allowed
            storage.resolved = true

            do {
                let name = try url.resourceValues(forKeys: [.localizedNameKey])
                if let name = name.allValues[.localizedNameKey] as? String {
                    storage.name = name
                }
            } catch {}

            storage.pathBookmark = bookmark

            withAnimation {
                viewModel.preferences.storageScopes[storage.uuid] = storage
            }
        }
    }
}
