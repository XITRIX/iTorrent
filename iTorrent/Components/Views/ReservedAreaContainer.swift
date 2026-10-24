import SwiftUI

struct ReservedAreaContainer<Content: View>: View {
    let edge: VerticalEdge
    let margin: CGFloat

    private let content: Content

    init(
        edge: VerticalEdge = .bottom,
        margin: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.edge = edge
        self.margin = margin
        self.content = content()
    }

    var body: some View {
        if #available(iOS 27.1, *) {
            ReservedAreaContainerContent(edge: edge, margin: margin, content: { content })
        } else {
            content
                .padding()
        }
    }
}

@available(iOS 27.1, *)
struct ReservedAreaContainerContent<Content: View>: View {
    let edge: VerticalEdge
    let margin: CGFloat

    private let content: Content

    init(
        edge: VerticalEdge = .bottom,
        margin: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.edge = edge
        self.margin = margin
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let regions =
                geometry.reservedRegions(kind: .occlusion)
                    .map(\.frame)
                + geometry.reservedRegions(kind: .division)
                    .map(\.frame)

            AvoidingLayout(
                edge: edge,
                margin: margin,
                regions: regions
            ) {
                content
            }
        }
        .ignoresSafeArea()
    }
}

@available(iOS 27.1, *)
private struct AvoidingLayout: Layout {
    let edge: VerticalEdge
    let margin: CGFloat
    let regions: [CGRect]

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard let child = subviews.first else { return }

        let inset = max(0, margin)
        let left = min(inset, bounds.width / 2)
        let right = max(left, bounds.width - inset)

        let fullWidth = right - left
        let maxHeight = max(0, bounds.height - 2 * inset)

        // Measure at the initially available width.
        var height = min(
            child.sizeThatFits(
                .init(width: fullWidth, height: nil)
            ).height,
            maxHeight
        )

        // Recalculate when reducing the width changes
        // the child's intrinsic height.
        for _ in 0..<4 {
            let segment = availableSegment(for: height, in: bounds)

            let width = segment?.width ?? 0
            let nextHeight = min(
                child.sizeThatFits(
                    .init(width: width, height: nil)
                ).height,
                maxHeight
            )

            if abs(nextHeight - height) < 0.5 {
                break
            }

            height = nextHeight
        }

        let segment = availableSegment(for: height, in: bounds)

        guard let segment, segment.width > 0 else {
            return
        }

        child.place(
            at: CGPoint(
                x: bounds.minX + segment.minX,
                y: bounds.minY + segment.minY
            ),
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: segment.width,
                height: height
            )
        )
    }

    private func availableSegment(for height: CGFloat, in bounds: CGRect) -> CGRect? {
        let inset = max(0, margin)
        let left = min(inset, bounds.width / 2)
        let right = max(left, bounds.width - inset)
        let top = inset
        let bottom = bounds.height - inset - height
        guard top <= bottom else { return nil }

        let preferredY = edge == .top ? top : bottom
        let alternatives = regions.map { region in
            edge == .top ? max(top, region.maxY) : min(bottom, region.minY - height)
        }
        let candidates = [preferredY] + alternatives.sorted {
            edge == .top ? $0 < $1 : $0 > $1
        }

        // Keep the existing edge placement when it fits. If an occlusion spans
        // the entire row (for example the portrait status area), move inward.
        for y in candidates where y >= top && y <= bottom {
            let band = CGRect(x: left, y: y, width: right - left, height: height)
            if let segment = widestFreeSegment(in: band), segment.width > 0 {
                return segment
            }
        }
        return nil
    }

    private func widestFreeSegment(
        in band: CGRect
    ) -> CGRect? {
        var segments: [CGRect] = [band]

        for obstacle in regions where obstacle.intersects(band) {
            segments = segments.flatMap { segment -> [CGRect] in
                let start = max(segment.minX, obstacle.minX)
                let end = min(segment.maxX, obstacle.maxX)

                guard start < end else {
                    return [segment]
                }

                var pieces: [CGRect] = []

                if start > segment.minX {
                    pieces.append(CGRect(
                        x: segment.minX,
                        y: segment.minY,
                        width: start - segment.minX,
                        height: segment.height
                    ))
                }

                if end < segment.maxX {
                    pieces.append(CGRect(
                        x: end,
                        y: segment.minY,
                        width: segment.maxX - end,
                        height: segment.height
                    ))
                }

                return pieces
            }
        }

        return segments.max { $0.width < $1.width }
    }
}
