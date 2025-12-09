//
//  ContentView.swift
//  iTorrent-TV
//
//  Created by Daniil Vinogradov on 09/12/2025.
//

import LibTorrent
import MvvmFoundation
import SwiftUI
import Combine

struct ContentView: View {
    private var torrents: [TorrentHandle] {
        torrentService.torrents.values.filter(\.snapshot.isValid).sorted { first, second in
            first.snapshot.name.localizedCaseInsensitiveCompare(second.snapshot.name) == .orderedAscending
        }
    }

    @FocusState var focusedTorrent: TorrentHandle?
    @State var selectedTorrent: TorrentHandle?
//    @State var lastFocusedTorrent: TorrentHandle? = Self.torrents.first ?? ""
    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State var navigationPath: NavigationPath = .init()
    @EnvironmentObject var torrentService: TorrentService

//    private var currentID: String { focusedTorrent ?? selectedTorrent }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                List(selection: $selectedTorrent) {
                    HStack {
                        Button("Add Torrent", systemImage: "plus") {
                            guard let url = Bundle.main.url(forResource: "test", withExtension: "torrent"),
                                  let torrentData = try? Data(contentsOf: url),
                                  let torrentFile = TorrentFile(with: torrentData)
                            else {
                                print("NONE!!!")
                                return
                            }

                            torrentService.addTorrent(by: torrentFile)
                            print("Success!!!")
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)

                        Button("Search", systemImage: "magnifyingglass") {}
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(torrents, id: \.self) { torrent in
                        TorrentItem(torrentHandle: torrent)
                            .focused($focusedTorrent, equals: torrent)
                            .listRowBackground(
                                (torrent == selectedTorrent && torrent != focusedTorrent)
                                    ? AnyView(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.2))
                                    )
                                    : AnyView(Color.clear)
                            )
                    }
                }
                .focusSection()
                .listStyle(.plain)
                .padding(.vertical, 22)
                .padding(.horizontal, 36)
                .scrollClipDisabled()
                //            .background(Color.blue)
                .clipped()
                .glassEffect(.regular, in: .rect(cornerRadius: 50))
                .padding(20)
                .ignoresSafeArea()
                .onAppear {
                    // Restore focus to the last focused or selected item
//                        focusedTorrent = lastFocusedTorrent
                }
                .onChange(of: focusedTorrent) { oldValue, newValue in
//                    if oldValue == nil {
//                        focusedTorrent = lastFocusedTorrent
//                        return
//                    }

                    guard let newValue else { return }
//                    lastFocusedTorrent = newValue
                    selectedTorrent = newValue
                    navigationPath = .init()
                }
                .frame(width: geometry.size.width / 3)

                NavigationStack(path: $navigationPath) {
                    if let selectedTorrent {
                        TorrentDetailsView(torrentHandle: selectedTorrent)
                    }
                }
                .frame(width: geometry.size.width * 2 / 3)
                .focusSection()
            }
        }
    }
}

struct TorrentItem: View {
    class ViewModel: ObservableObject {
        @Published var title: String = ""
        @Published var progressText: String = ""
        @Published var status: String = ""
        @Published var progress: Double = 0

        init(torrentHandle: TorrentHandle) {
            self.torrentHandle = torrentHandle
            updateState()
            
            disposeBag.bind {
                torrentHandle.updatePublisher.sink { [weak self] _ in
                    self?.updateState()
                }
            }
        }

        private var disposeBag = DisposeBag()
        private var torrentHandle: TorrentHandle

        private func updateState() {
            let percent = "\(String(format: "%.2f", torrentHandle.snapshot.progress * 100))%"

            title = torrentHandle.snapshot.name
            progressText = %"\(torrentHandle.snapshot.totalWantedDone.bitrateToHumanReadable) of \(torrentHandle.snapshot.totalWanted.bitrateToHumanReadable) (\(percent))"
            status = "\(torrentHandle.snapshot.stateText)"
            progress = torrentHandle.snapshot.progress
        }
    }

    @Environment(\.isFocused) var isFocused

    @StateObject private var viewModel: ViewModel

    init(torrentHandle: TorrentHandle) {
        _viewModel = .init(wrappedValue: .init(torrentHandle: torrentHandle))
    }

    var body: some View {
        Button {} label: {
            VStack(alignment: .leading) {
                Text(viewModel.title)

                Group {
                    Text(viewModel.progressText)
                    Text(viewModel.status)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                ProgressView(value: viewModel.progress)
            }
            .padding(.vertical, 8)
            //                        .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
