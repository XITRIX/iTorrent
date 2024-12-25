//
//  TrackersListDetailsPreferencesView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 16/09/2024.
//

import LibTorrent
@preconcurrency import MvvmFoundation
import SwiftUI

class TrackersListDetailsPreferencesViewModel: BaseViewModelWith<TrackersListService.ListState>, ObservableObject, @unchecked Sendable {
    @Published var trackers: [String] = []
    @Published var title: String = ""
    @Published var source: TrackersListService.ListState.Source!

    override func prepare(with model: TrackersListService.ListState) {
        source = model.source
        trackers = model.trackers
        title = model.title
    }

    @MainActor
    func addTracker() {
        #if os(visionOS)
        textInput(title: %"trackers.add.title.single", message: %"trackers.add.message.single", placeholder: "http://x.x.x.x:8080/announce", cancel: %"common.cancel", accept: %"common.add") { [unowned self] result in
            guard let url = URL(string: result ?? "") else { return }

            withAnimation {
                trackers.append(url.absoluteString)
                trackers.removeDuplicates()
                trackersListService.trackerSources.value[source]?.trackers = trackers
            }
        }
        #else
        textMultilineInput(title: %"trackers.add.title", message: %"trackers.add.message", placeholder: "http://x.x.x.x:8080/announce", accept: %"common.add") { [unowned self] result in
            guard let result else { return }

            withAnimation {
                result.components(separatedBy: .newlines).forEach { urlString in
                    guard let url = URL(string: urlString) else { return }
                    trackers.append(url.absoluteString)
                }

                trackers.removeDuplicates()
                trackersListService.trackerSources.value[source]?.trackers = trackers
            }
        }
        #endif
    }

    func removeTracker(_ tracker: String) {
        trackers.removeAll(where: { $0 == tracker })
        trackersListService.trackerSources.value[source]?.trackers = trackers
    }

    @Injected var trackersListService: TrackersListService
}

struct TrackersListDetailsPreferencesView<VM: TrackersListDetailsPreferencesViewModel>: MvvmSwiftUIViewProtocol {
    @ObservedObject var viewModel: VM
    var title: String

    init(viewModel: VM) {
        self.viewModel = viewModel
        title = viewModel.title
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.trackers, id: \.self) { tracker in
                    Button {
                        UIPasteboard.general.string = tracker
                        viewModel.alertWithTimer(1, title: %"trackers.action.copy")
                    } label: {
                        Text(tracker)
                            .foregroundStyle(Color(uiColor: .label))
                    }
                    .swipeActions {
                        if case .local = viewModel.source {
                            Button {
                                withAnimation {
                                    viewModel.removeTracker(tracker)
                                }
                            } label: {
                                Image(systemName: "trash")
                            }.tint(.red)
                        }
                    }
                }
            }
        }
    }
}

class TrackersListDetailsPreferencesViewController: BaseHostingViewController<TrackersListDetailsPreferencesView<TrackersListDetailsPreferencesViewModel>> {
    private lazy var addButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: .init(title: "") { [unowned self] _ in
        viewModel.addTracker()
    })

    override func viewDidLoad() {
        super.viewDidLoad()

        if case .local = viewModel.source {
            navigationItem.trailingItemGroups.append(.fixedGroup(items: [addButtonItem]))
        }
    }
}
