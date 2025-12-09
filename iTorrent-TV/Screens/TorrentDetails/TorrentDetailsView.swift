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
                            DetailView(title: "State", detail: "Done")
                        }
                    }

        //            Section {
        //                DetailView(title: "State", detail: "Done")
        //            } header: {
        //                Text("Downloading")
        //            }

                    Section {
                        VStack {
                            DetailView(title: "Hash", detail: "284d665fc0c912286d1505d6372140281384cb6d")
                            DetailView(title: "Creator", detail: "iTorrent 2.1.0")
                            DetailView(title: "Created", detail: "17/11/2025")
                            DetailView(title: "Added", detail: "17/11/2025")
                        }
                    } header: {
                        Text("Primary Info")
                    }

                    Section {
                        VStack {
                            DetailView(title: "Selected/Total", detail: "9.3 GB / 24.9 GB")
                            DetailView(title: "Completed", detail: "9.3 GB")
                            DetailView(title: "Progress Selected/Total", detail: "100.00% / 100.00%")
                            DetailView(title: "Downloaded", detail: "0 B")
                            DetailView(title: "Uploaded", detail: "0 B")
                            DetailView(title: "Seeders", detail: "0(0)")
                            DetailView(title: "Leechers", detail: "0(29)")
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
    let title: String
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
