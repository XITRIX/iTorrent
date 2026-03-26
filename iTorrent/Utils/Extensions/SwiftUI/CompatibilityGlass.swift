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
    func compatibilityGlassEffect(isClear: Bool = false, interactive: Bool = false) -> some View {
        compatibilityGlassEffect(in: Capsule(), isClear: isClear, interactive: interactive)
    }

    @ViewBuilder
    func compatibilityGlassEffect<S: Shape>(
        in shape: S,
        isClear: Bool = false,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            let glass = isClear ? Glass.clear : .regular
            if interactive {
                glassEffect(glass.interactive(), in: shape)
            } else {
                glassEffect(glass, in: shape)
            }
        } else {
            background(isClear ? .thinMaterial : .regular, in: shape)
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
