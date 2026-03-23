//
//  ResolvedTintColorKey.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 20.03.2026.
//

import SwiftUI
import UIKit

private struct ResolvedTintColorKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private extension EnvironmentValues {
    var resolvedTintColor: Color? {
        get { self[ResolvedTintColorKey.self] }
        set { self[ResolvedTintColorKey.self] = newValue }
    }
}

private struct TintObserverModifier: ViewModifier {
    @State private var resolvedTintColor: Color?

    func body(content: Content) -> some View {
        content
            .environment(\.resolvedTintColor, resolvedTintColor)
            .background {
                TintObserverView(resolvedTintColor: $resolvedTintColor)
                    .frame(width: 0, height: 0)
            }
    }
}

private struct TintObserverView: UIViewRepresentable {
    @Binding var resolvedTintColor: Color?

    func makeUIView(context: Context) -> TintMonitoringView {
        let view = TintMonitoringView()
        view.onTintColorChanged = context.coordinator.handleTintColorChange(_:)
        return view
    }

    func updateUIView(_ uiView: TintMonitoringView, context: Context) {
        context.coordinator.resolvedTintColor = $resolvedTintColor
        uiView.onTintColorChanged = context.coordinator.handleTintColorChange(_:)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(resolvedTintColor: $resolvedTintColor)
    }

    final class Coordinator {
        var resolvedTintColor: Binding<Color?>

        init(resolvedTintColor: Binding<Color?>) {
            self.resolvedTintColor = resolvedTintColor
        }

        func handleTintColorChange(_ color: Color) {
            guard resolvedTintColor.wrappedValue != color else { return }

            let resolvedTintColor = resolvedTintColor

            DispatchQueue.main.async {
                resolvedTintColor.wrappedValue = color
            }
        }
    }
}

private final class TintMonitoringView: UIView {
    var onTintColorChanged: ((Color) -> Void)?

    override func tintColorDidChange() {
        super.tintColorDidChange()
        refreshTintColor()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshTintColor()
    }

    func refreshTintColor() {
        guard let tintColor else { return }
        onTintColorChanged?(.init(uiColor: tintColor))
    }
}

struct TintAwareShapeStyle: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        if let resolvedTintColor = environment.resolvedTintColor {
            AnyShapeStyle(resolvedTintColor)
        } else {
            AnyShapeStyle(.tint)
        }
    }
}

extension ShapeStyle where Self == TintAwareShapeStyle {
    static var tintAware: TintAwareShapeStyle { .init() }
}

extension View {
    func monitorTintColor() -> some View {
        modifier(TintObserverModifier())
    }

    @ViewBuilder
    func tintAwareForegroundStyle(_ replacementColor: Color? = nil) -> some View {
        if let replacementColor {
            foregroundStyle(replacementColor)
        } else {
            self.monitorTintColor()
                .foregroundStyle(.tintAware)
        }
    }
}
