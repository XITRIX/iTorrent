//
//  CompatibilityGlass.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.09.2025.
//

import SwiftUI

struct CompatibilityGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

extension View {
    @ViewBuilder
    func compatibilityGlassEffect() -> some View {
        compatibilityGlassEffect(in: Capsule())
    }

    @ViewBuilder
    func compatibilityGlassEffect<S: Shape>(
        in shape: S,
        fallbackMaterial: Material? = .thin,
        interactive: Bool = true
    ) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                glassEffect(.clear.interactive(), in: shape)
            } else {
                glassEffect(.clear, in: shape)
            }
        } else if let fallbackMaterial {
            background(fallbackMaterial, in: shape)
        } else {
            self
        }
    }

    @ViewBuilder
    func compatibilityGlassTransition() -> some View {
        if #available(iOS 26.0, *) {
            glassEffectTransition(.materialize)
        } else {
            self
        }
    }

    @ViewBuilder
    func compatibilityGlassID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}
