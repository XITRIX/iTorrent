//
//  BCHostingConfiguration.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.06.2024.
//

import SwiftUI
import UIKit

/// Backward Compatibility (BC) implementation of UIHostingConfiguration for iOS 15 and less
/// Apple's implementation contains a lot of extra functionalities that will be almost impossible to reimplement so better not use this implementation
/// It will stay here as historical artifact
public struct BCHostingConfiguration<Content>: UIContentConfiguration where Content: View {
    public func makeContentView() -> any UIView & UIContentView {
        ContentView(configuration: self)
    }

    public func updated(for state: any UIConfigurationState) -> BCHostingConfiguration<Content> {
        self
    }

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private let content: Content
}

private extension BCHostingConfiguration {
    class ContentView: UIView, UIContentView {
        var configuration: any UIContentConfiguration

        init(configuration: any UIContentConfiguration) {
            self.configuration = configuration
            super.init(frame: .zero)
            preservesSuperviewLayoutMargins = true
            updateConfiguration()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            controller?.view.intrinsicContentSize ?? .zero
        }

        override func invalidateIntrinsicContentSize() {
            super.invalidateIntrinsicContentSize()
            controller?.view.invalidateIntrinsicContentSize()
        }

        private func updateConfiguration() {
            guard let configuration = configuration as? BCHostingConfiguration
            else { return }

            controller?.view.removeFromSuperview()
            controller = configuration.content.asController

            guard let subview = controller?.view else { return }

            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.backgroundColor = .clear

            addSubview(subview)
            NSLayoutConstraint.activate([
                layoutMarginsGuide.leadingAnchor.constraint(equalTo: subview.leadingAnchor),
                layoutMarginsGuide.topAnchor.constraint(equalTo: subview.topAnchor),
                subview.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                subview.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            ])
        }

        private var controller: UIHostingController<Content>?
    }
}
