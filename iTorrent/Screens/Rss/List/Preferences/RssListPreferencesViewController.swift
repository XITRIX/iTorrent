//
//  RssListPreferencesViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.04.2024.
//

import MvvmFoundation
import SwiftUI
import UIKit

class RssListPreferencesViewController<VM: RssListPreferencesViewModel>: BaseCollectionViewController<VM> {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Preferences"

        // FIXME: Dirty hack for better looking top appearance, should be fixed!!!
        navigationItem.largeTitleDisplayMode = .always
        collectionView.isScrollEnabled = false
        collectionView.dragInteractionEnabled = false

        token = collectionView.observe(\.contentSize, options: [.new]) { [unowned self] view, change in
            preferredContentSize = view.contentSize
        }

//        applyBottomSheetDetents(with: collectionView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        invalidateBottomSheetDetents()
    }

    private var token: NSKeyValueObservation?
}

// class RssListPreferencesViewController<VM: RssListPreferencesViewModel>: UIHostingController<RssListPreferencesView>, MvvmViewControllerProtocol {
//    let viewModel: VM
//
//    required init(viewModel: VM) {
//        self.viewModel = viewModel
//        super.init(rootView: .init())
//        self.viewModel.setNavigationService { [unowned self] in self }
//    }
//
//    @available(*, unavailable)
//    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        title = "Preferences"
//
////        if #available(iOS 16.4, *) {
////            safeAreaRegions = []
////        }
//
//        // FIXME: Dirty hack for better looking top appearance, should be fixed!!!
//        navigationItem.largeTitleDisplayMode = .never
//
////        DispatchQueue.main.async { [self] in
////            applyBottomSheetDetents(with: contentScrollView(for: .top))
////        }
//        applyBottomSheetDetents(with: { [unowned self] in
//            view.systemLayoutSizeFitting(.init(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
//        })
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        invalidateBottomSheetDetents()
//    }
// }

// struct RssListPreferencesView: View {
//    @Environment(\.layoutMarginsInsets) var layoutMarginsInsets
//
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Text(String("Hello world"))
//                Spacer()
//            }
//            .systemMinimumHeight()
//            .padding([.leading, .trailing])
//            .padding([.top, .bottom], 8)
////            .background(Color.red)
//
//            Divider()
//                .padding(.leading)
//
//            HStack {
//                Text(String("Hello world"))
//                Spacer()
//            }
//            .systemMinimumHeight()
//            .padding([.leading, .trailing])
//            .padding([.top, .bottom], 8)
//
//            Divider()
//                .padding(.leading)
//
//            HStack {
//                Text(String("Hello world"))
//                Spacer()
//            }
//            .systemMinimumHeight()
//            .padding([.leading, .trailing])
//            .padding([.top, .bottom], 8)
//
//            Divider()
//                .padding(.leading)
//
//            HStack {
//                Text(String("Hello world"))
//                Spacer()
//            }
//            .systemMinimumHeight()
//            .padding([.leading, .trailing])
//            .padding([.top, .bottom], 8)
//        }.frame(maxWidth: .infinity)
//            .background(Color(uiColor: .secondarySystemGroupedBackground))
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            .padding(.leading, layoutMarginsInsets.leading)
//            .padding(.trailing, layoutMarginsInsets.trailing)
//            .background(Color(uiColor: .systemGroupedBackground))
//
//    }
// }
//
// #Preview {
//    RssListPreferencesView()
// }
