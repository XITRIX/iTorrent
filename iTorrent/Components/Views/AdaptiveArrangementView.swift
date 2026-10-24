import SwiftUI

/// The current placement used by `AdaptiveArrangementView`.
@available(iOS 27.1, *)
enum AdaptiveArrangementMode: Equatable {
    case unfolded
    case book
    case tabletop
}

@available(iOS 27.1, *)
private struct AdaptiveArrangementModeKey: EnvironmentKey {
    static let defaultValue: AdaptiveArrangementMode = .unfolded
}

@available(iOS 27.1, *)
extension EnvironmentValues {
    var adaptiveArrangementMode: AdaptiveArrangementMode {
        get { self[AdaptiveArrangementModeKey.self] }
        set { self[AdaptiveArrangementModeKey.self] = newValue }
    }
}

/// A fold-aware, identity-preserving alternative to `ArrangementView`.
///
/// - Unfolded: both views have the full container frame; primary overlays secondary.
/// - Book pose (vertical hinge): secondary stays full-frame; primary moves to
///   the trailing or leading pane.
/// - Tabletop pose (horizontal hinge): secondary and primary occupy opposite
///   sides of the hinge; by default the secondary is above and primary below.
///
/// Neither view is conditionally inserted/removed: only their frames change.
struct AdaptiveArrangementView<Primary: View, Secondary: View>: View {
    private let primary: Primary
    private let secondary: Secondary
    private let bookPrimaryEdge: HorizontalEdge
    private let tabletopPrimaryEdge: VerticalEdge

    init(
        bookPrimaryEdge: HorizontalEdge = .trailing,
        tabletopPrimaryEdge: VerticalEdge = .bottom,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.primary = primary()
        self.secondary = secondary()
        self.bookPrimaryEdge = bookPrimaryEdge
        self.tabletopPrimaryEdge = tabletopPrimaryEdge
    }

    var body: some View {
        if #available(iOS 27.1, *) {
            AdaptiveArrangementViewHolder(bookPrimaryEdge: bookPrimaryEdge, tabletopPrimaryEdge: tabletopPrimaryEdge, primary: { primary }, secondary: { secondary })
        } else {
            ZStack {
                secondary
                primary
            }
        }
    }
}

@available(iOS 27.1, *)
struct AdaptiveArrangementViewHolder<Primary: View, Secondary: View>: View {
    private let primary: Primary
    private let secondary: Secondary
    private let bookPrimaryEdge: HorizontalEdge
    private let tabletopPrimaryEdge: VerticalEdge

    @Environment(\.layoutDirection) private var layoutDirection

    init(
        bookPrimaryEdge: HorizontalEdge = .trailing,
        tabletopPrimaryEdge: VerticalEdge = .bottom,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.primary = primary()
        self.secondary = secondary()
        self.bookPrimaryEdge = bookPrimaryEdge
        self.tabletopPrimaryEdge = tabletopPrimaryEdge
    }

    var body: some View {
        GeometryReader { proxy in
            let bounds = CGRect(origin: .zero, size: proxy.size)
            // This query returns only active division regions by default.
            let hinge = proxy.reservedRegions(kind: .division)
                .map(\.frame)
                .first { $0.intersects(bounds) }
            let placement = placement(in: bounds, hinge: hinge)

            ZStack(alignment: .topLeading) {
                secondary
                    .frame(
                        width: placement.secondary.width,
                        height: placement.secondary.height
                    )
                    .position(
                        x: placement.secondary.midX,
                        y: placement.secondary.midY
                    )
                    .environment(\.adaptiveArrangementMode, placement.mode)

                primary
                    .frame(
                        width: placement.primary.width,
                        height: placement.primary.height
                    )
                    .position(
                        x: placement.primary.midX,
                        y: placement.primary.midY
                    )
                    .environment(\.adaptiveArrangementMode, placement.mode)
            }
            .frame(width: bounds.width, height: bounds.height)
        }
    }

    private func placement(in bounds: CGRect, hinge: CGRect?) -> Placement {
        guard let hinge else {
            return Placement(primary: bounds, secondary: bounds, mode: .unfolded)
        }

        if hinge.height > hinge.width {
            // Vertical hinge: keep the secondary covering both panes.
            let rightSide = (bookPrimaryEdge == .trailing)
                == (layoutDirection == .leftToRight)
            let primary: CGRect

            if rightSide {
                let x = clamp(hinge.maxX, to: bounds.minX...bounds.maxX)
                primary = CGRect(
                    x: x, y: bounds.minY,
                    width: bounds.maxX - x, height: bounds.height
                )
            } else {
                let maxX = clamp(hinge.minX, to: bounds.minX...bounds.maxX)
                primary = CGRect(
                    x: bounds.minX, y: bounds.minY,
                    width: maxX - bounds.minX, height: bounds.height
                )
            }
            return Placement(primary: primary, secondary: bounds, mode: .book)
        } else {
            // Horizontal hinge: separate views above and below the fold.
            let topEnd = clamp(hinge.minY, to: bounds.minY...bounds.maxY)
            let bottomStart = clamp(hinge.maxY, to: bounds.minY...bounds.maxY)
            let top = CGRect(
                x: bounds.minX, y: bounds.minY,
                width: bounds.width, height: topEnd - bounds.minY
            )
            let bottom = CGRect(
                x: bounds.minX, y: bottomStart,
                width: bounds.width, height: bounds.maxY - bottomStart
            )
            let primaryAtTop = tabletopPrimaryEdge == .top
            return Placement(
                primary: primaryAtTop ? top : bottom,
                secondary: primaryAtTop ? bottom : top,
                mode: .tabletop
            )
        }
    }

    private func clamp(_ value: CGFloat, to bounds: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, bounds.lowerBound), bounds.upperBound)
    }

    private struct Placement: Equatable {
        let primary: CGRect
        let secondary: CGRect
        let mode: AdaptiveArrangementMode
    }
}
