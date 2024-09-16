//
//  TrackersListPreferencesView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 16/09/2024.
//

import LibTorrent
import MvvmFoundation
import SwiftUI

class TrackersListPreferencesViewModel: BaseViewModel, ObservableObject {
    @Published var sorces: [TrackersListService.ListState] = []
    @Published var isAutoaddingEnabled: Bool

    required init() {
        isAutoaddingEnabled = PreferencesStorage.shared.isTrackersAutoaddingEnabled
        super.init()

        disposeBag.bind {
            $isAutoaddingEnabled.sink { value in
                PreferencesStorage.shared.isTrackersAutoaddingEnabled = value
            }

            trackersListService.trackerSources.uiSink { [unowned self] values in
                withAnimation {
                    sorces = Array(values.values)
                }
            }
        }
    }

    func addRemoteTracker() {
        textInputs(title: %"preferences.trackers.add.title", textInputs: [
            .init(placeholder: %"preferences.trackers.add.titlePlaceholder"),
            .init(placeholder: %"preferences.trackers.add.urlPlaceholder")
        ]) { [weak self] results in
            guard let self,
                  let results,
                  let url = URL(string: results[1])
            else { return }

            Task {
                guard !self.trackersListService.trackerSources.value.keys.contains(where: { $0 == .remote(url) }) else {
                    self.alert(title: %"preferences.trackers.exists.title", actions: [.init(title: %"common.ok", style: .cancel)])
                    return
                }
                try await self.trackersListService.addTrackersSource(url, title: results[0])
            }
        }
    }

    func addLocalTracker() {
        textInput(title: %"preferences.trackers.add.title", placeholder: %"preferences.trackers.add.titlePlaceholder") { [weak self] text in
            guard let self, let text
            else { return }

            self.trackersListService.createLocalSource(title: text)
        }
    }

    func showDetails(_ model: TrackersListService.ListState) {
        navigate(to: TrackersListDetailsPreferencesViewModel.self, with: model, by: .show)
    }

    func renameDetails(_ model: TrackersListService.ListState) {
        textInput(title: %"preferences.trackers.rename.title", placeholder: model.title, defaultValue: model.title) { [weak self] result in
            guard let self, let result, !result.isEmpty else { return }
            trackersListService.trackerSources.value[model.source]?.title = result
        }
    }

    @Injected var trackersListService: TrackersListService
}

struct TrackersListPreferencesView<VM: TrackersListPreferencesViewModel>: MvvmSwiftUIViewProtocol {
    @ObservedObject var viewModel: VM
    var title: String = %"preferences.network.trackers"

    init(viewModel: VM) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if !viewModel.sorces.isEmpty {
                Section {
                    Toggle(isOn: $viewModel.isAutoaddingEnabled) {
                        Text("preferences.trackers.autoadding")
                    }
                } footer: {
                    Text("preferences.trackers.autoadding.footer")
                }
                Section {
                    ForEach(viewModel.sorces) { state in
                        Button {
                            viewModel.showDetails(state)
                        } label: {
                            NavigationLink(state.title, destination: EmptyView())
                        }
                        .foregroundColor(Color(uiColor: .label))
                        .swipeActions {
                            Button {
                                viewModel.alert(title: %"preferences.trackers.remove.title", message: %"preferences.trackers.remove.message", actions: [
                                    .init(title: %"common.cancel", style: .cancel),
                                    .init(title: %"common.remove", style: .destructive, action: {
                                        withAnimation {
                                            viewModel.trackersListService.trackerSources.value[state.source] = nil
                                        }
                                    })
                                ])
                            } label: {
                                Image(systemName: "trash")
                            }.tint(.red)

                            Button {
                                viewModel.renameDetails(state)
                            } label: {
                                Image(systemName: "character.textbox")
                            }.tint(.init(uiColor: PreferencesStorage.shared.tintColor))
                        }
                    }
                }
            }
        }
        .overlay {
            if viewModel.sorces.isEmpty {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("preferences.trackers.empty.title", systemImage: "folder", description: Text("preferences.trackers.empty.message"))
                }
            }
        }
    }
}

class TrackersListPreferencesViewController: BaseHostingViewController<TrackersListPreferencesView<TrackersListPreferencesViewModel>> {
    private lazy var addButtonItem = UIBarButtonItem(systemItem: .add, menu: .init(title: %"trackersList.add", children: [
        UIAction(title: %"trackersList.add.remote", image: .init(systemName: "link")) { [unowned self] _ in
            viewModel.addRemoteTracker()
        },
        UIAction(title: %"trackersList.add.local", image: .init(systemName: "opticaldiscdrive.fill")) { [unowned self] _ in
            viewModel.addLocalTracker()
        }
    ]))

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.trailingItemGroups.append(.fixedGroup(items: [addButtonItem]))
    }
}
