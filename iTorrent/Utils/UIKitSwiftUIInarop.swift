//
//  UIKitSwiftUIInarop.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01/11/2023.
//

import SwiftUI

private struct GenericControllerView: UIViewControllerRepresentable {
    let viewController: UIViewController
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    var asController: UIHostingController<Self> {
        let vc = UIHostingController<Self>(rootView: self)
        if #available(iOS 16.4, *) {
            vc.safeAreaRegions = []
        }
        return vc
    }
}

extension UIViewController {
    var asView: some View {
        GenericControllerView(viewController: self)
    }
}
