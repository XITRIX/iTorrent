//
//  TrackerCellView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import SwiftUI
import MvvmFoundation
import LibTorrent

struct TrackerCellView: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: TrackerCellViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .fontWeight(.semibold)
            HStack {
                HStack {
                    Text("tracker.peers")
                    Text(viewModel.peers.string)
                }
                Spacer()
                HStack {
                    Text("tracker.seeds")
                    Text(viewModel.seeds.string)
                }
                Spacer()
                HStack {
                    Text("tracker.leeches")
                    Text(viewModel.leeches.string)
                }
            }
            HStack {
                Text("tracker.state")
                Text(viewModel.state.name)
            }
            if let message = viewModel.message,
               !message.isEmpty
            {
                Text("tracker.message: \(message)")
            }
        }
        .systemMinimumHeight()
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }
        cell.accessories = [.multiselect(displayed: .whenEditing)]
    }
}

private extension Int {
    var string: String {
        guard self != -1 else { return %"tracker.na" }
        return "\(self)"
    }
}

private extension TorrentTracker.State {
    var name: String {
        switch self {
        case .notContacted:
            return %"tracker.state.notContacted"
        case .working:
            return %"tracker.state.working"
        case .updating:
            return %"tracker.state.updating"
        case .notWorking:
            return %"tracker.state.notWorking"
        case .trackerError:
            return %"tracker.state.trackerError"
        case .unreachable:
            return %"tracker.state.unreachable"
        @unknown default:
            assertionFailure("Unregistered \(Self.self) enum value is not allowed: \(self)")
            return ""
        }
    }
}

#Preview {
    let vm = TrackerCellViewModel()
    vm.title = "Top tracker"
    vm.peers = 390
    vm.leeches = 230
    vm.seeds = 5200

    vm.message = "Top tracker"
    return TrackerCellView(viewModel: vm)
        .frame(maxWidth: .infinity)
//        .border(Color.blue)
}
