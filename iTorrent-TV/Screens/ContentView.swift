//
//  ContentView.swift
//  iTorrent-TV
//
//  Created by Daniil Vinogradov on 09/12/2025.
//

import Combine
import LibTorrent
import MvvmFoundation
import SwiftUI

struct ContentView: View {
    private var torrents: [TorrentSession.Handle.Snapshot] {
        torrentService.modernHandles.values
            .compactMap(\.currentSnapshot)
            .filter(\.isValid)
            .sorted { first, second in
                first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    @FocusState private var focusedTorrent: TorrentSession.Hashes?
    @State private var selectedTorrent: TorrentSession.Hashes?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var navigationPath: NavigationPath = .init()
    @EnvironmentObject private var torrentService: TorrentService

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                List(selection: $selectedTorrent) {
                    HStack {
                        Button("Add Torrent", systemImage: "plus") {
                            guard let url = Bundle.main.url(forResource: "test", withExtension: "torrent"),
                                  let torrentData = try? Data(contentsOf: url),
                                  let source = TorrentSession.Source(torrentData: torrentData)
                            else {
                                print("NONE!!!")
                                return
                            }

                            torrentService.addTorrent(source)
                            print("Success!!!")
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)

                        Button("Search", systemImage: "magnifyingglass") {}
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(torrents, id: \.infoHashes) { torrent in
                        TorrentItem(snapshot: torrent)
                            .focused($focusedTorrent, equals: torrent.infoHashes)
                            .listRowBackground(
                                (torrent.infoHashes == selectedTorrent && torrent.infoHashes != focusedTorrent)
                                    ? AnyView(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.2))
                                    )
                                    : AnyView(Color.clear)
                            )
                            .tag(torrent.infoHashes)
                    }
                }
                .focusSection()
                .listStyle(.plain)
                .padding(.vertical, 22)
                .padding(.horizontal, 36)
                .scrollClipDisabled()
                .clipped()
                .glassEffect(.regular, in: .rect(cornerRadius: 50))
                .padding(20)
                .ignoresSafeArea()
                .onChange(of: focusedTorrent) { _, newValue in
                    guard let newValue else { return }
                    selectedTorrent = newValue
                    navigationPath = .init()
                }
                .frame(width: geometry.size.width / 3)

                NavigationStack(path: $navigationPath) {
                    if let selectedTorrent {
                        TorrentDetailsView(infoHashes: selectedTorrent)
                    }
                }
                .frame(width: geometry.size.width * 2 / 3)
                .focusSection()
            }
        }
    }
}

struct TorrentItem: View {
    let snapshot: TorrentSession.Handle.Snapshot

    var body: some View {
        let percent = "\(String(format: "%.2f", snapshot.progress * 100))%"

        Button {} label: {
            VStack(alignment: .leading) {
                Text(snapshot.name)

                Group {
                    Text(%"\(snapshot.totalWantedDone.bitrateToHumanReadable) of \(snapshot.totalWanted.bitrateToHumanReadable) (\(percent))")
                    Text("\(snapshot.stateText)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                ProgressView(value: snapshot.progress)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
