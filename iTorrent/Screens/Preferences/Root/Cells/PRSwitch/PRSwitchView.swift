//
//  PRSwitchView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import MvvmFoundation
import SwiftUI
import CombineCocoa

class PRSwitchView<VM: PRSwitchViewModel>: MvvmCollectionViewListCell<VM> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var switchView: UISwitch!

    override func setup(with viewModel: VM) {
        switchView.isOn = viewModel.value.wrappedValue

        disposeBag.bind {
            viewModel.$title.sink { [titleLabel] title in
                titleLabel?.text = title
            }
            switchView.isOnPublisher.sink { isOn in
                guard viewModel.value.wrappedValue != isOn else { return }
                viewModel.value.wrappedValue = isOn
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            print("++-+ \(frame.height)")
        }
    }
}

struct PRSwitchView1: MvvmSwiftUICellProtocol {
    @ObservedObject var viewModel: PRSwitchViewModel

    var body: some View {
        HStack {
            Toggle(viewModel.title, isOn: viewModel.value)
        }
    }

    static var registration: UICollectionView.CellRegistration<UICollectionViewListCell, PRSwitchViewModel> = .init { cell, indexPath, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [cell] in
            print("++-+ \(cell.frame.height)")
        }
//        cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
    }
}

#Preview {
    PRSwitchView1(viewModel: .init(with: .init(title: "Title", value: .constant(true))))
}
