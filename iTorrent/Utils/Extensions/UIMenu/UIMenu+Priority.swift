//
//  UIMenu+Priority.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import LibTorrent
import SwiftUI
import UIKit

extension UIMenu {
    static func makeForChangePriority( options: UIMenu.Options = [], _ setPriority: @escaping (FileEntry.Priority) -> ()) -> UIMenu {
        .init(title: %"prioriry.change.title", image: .init(resource: .icSort), options: options, children: [
            UIAction(title: String(localized: "prioriry.top"), image: .init(systemName: "gauge.with.dots.needle.100percent"), handler: { _ in
                setPriority(.topPriority)
            }),
            UIAction(title: String(localized: "prioriry.default"), image: .init(systemName: "gauge.with.dots.needle.50percent"), handler: { _ in
                setPriority(.defaultPriority)
            }),
            UIAction(title: String(localized: "prioriry.low"), image: .init(systemName: "gauge.with.dots.needle.0percent"), handler: { _ in
                setPriority(.lowPriority)
            }),
            UIAction(title: String(localized: "prioriry.dontDownload"), image: .init(systemName: "xmark.circle"), attributes: [.destructive], handler: { _ in
                setPriority(.dontDownload)
            })
        ])
    }
}

struct PriorityMenu: ViewModifier {
    let setPriority: (FileEntry.Priority) -> ()

    func body(content: Content) -> some View {
        Menu {
            Section(%"prioriry.change.title") {
                Button(%"prioriry.top", systemImage: "gauge.with.dots.needle.100percent") {
                    setPriority(.topPriority)
                }
                Button(%"prioriry.default", systemImage: "gauge.with.dots.needle.50percent") {
                    setPriority(.defaultPriority)
                }
                Button(%"prioriry.low", systemImage: "gauge.with.dots.needle.0percent") {
                    setPriority(.lowPriority)
                }
                Button(%"prioriry.dontDownload", systemImage: "xmark.circle", role: .destructive) {
                    setPriority(.dontDownload)
                }
            }
        } label: {
            content
        }
    }
}
