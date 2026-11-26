//
//  TorrentDetailsView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/12/2025.
//

import SwiftUI
import LibTorrent

struct TorrentDetailsView: View {
    let torrentHandle: TorrentHandle

    var body: some View {
        TabView {
            Tab {
                List {
                    Section {
                        Button("Delete With Files", role: .destructive) {
                            TorrentService.shared.removeTorrent(by: torrentHandle.infoHashes, deleteFiles: true)
                        }
                        .focusable()

                        Button("Delete Keeping Files", role: .destructive) {
                            TorrentService.shared.removeTorrent(by: torrentHandle.infoHashes, deleteFiles: false)
                        }
                        .focusable()
                    }

                    Section {
                        VStack {
                            DetailView(title: "details.state", detail: String(localized: "torrent.state.done"))
                        }
                    }

        //            Section {
        //                DetailView(title: "State", detail: "Done")
        //            } header: {
        //                Text("Downloading")
        //            }

                    Section {
                        VStack {
                            DetailView(title: "details.info.hash", detail: "284d665fc0c912286d1505d6372140281384cb6d")
                            DetailView(title: "details.info.creator", detail: "iTorrent 2.1.0")
                            DetailView(title: "details.info.created", detail: "17/11/2025")
                            DetailView(title: "details.info.added", detail: "17/11/2025")
                        }
                    } header: {
                        Text("Primary Info")
                    }

                    Section {
                        VStack {
                            DetailView(title: "details.transfer.selectedTotal", detail: "9.3 GB / 24.9 GB")
                            DetailView(title: "details.transfer.completed", detail: "9.3 GB")
                            DetailView(title: "details.transfer.progressSelectedTotal", detail: "100.00% / 100.00%")
                            DetailView(title: "details.transfer.downloaded", detail: "0 B")
                            DetailView(title: "details.transfer.uploaded", detail: "0 B")
                            DetailView(title: "details.transfer.seeders", detail: "0(0)")
                            DetailView(title: "details.transfer.leechers", detail: "0(29)")
                        }
                    } header: {
                        Text("Transfer")
                    }
                }
                .padding(.leading, 8)
                .listStyle(.grouped)
                .scrollClipDisabled()
            } label: {
                Text("General")
            }

            Tab {

            } label: {
                Text("Trackers")
            }

            Tab {

            } label: {
                Text("Peers")
            }

            Tab {
                TorrentFilesView(torrentHandle: torrentHandle, rootDirectory: nil)
            } label: {
                Text("Files")
            }
        }
        .navigationTitle(torrentHandle.snapshot.name)
    }
}

struct DetailView: View {
    let title: LocalizedStringKey
    let detail: String

    var body: some View {
        HStack {
            Text(title)
                .bold()
            Spacer()
            Text(detail)
                .foregroundStyle(.tint)
        }
        .padding()
        .focusable()
    }
}
