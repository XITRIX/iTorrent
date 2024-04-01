//
//  UISegmentedProgressView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 01.04.2024.
//

import SwiftUI
import UIKit

@IBDesignable
public class UISegmentedProgressView: UIView {
    public var progress: [Double] = [0.5] {
        didSet {
            guard oldValue != progress else { return }
            setNeedsDisplay()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override public var intrinsicContentSize: CGSize {
        .init(width: UIView.noIntrinsicMetric, height: defaultHeight)
    }

    override public func tintColorDidChange() {
        super.tintColorDidChange()
        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(bounds.size.height)
        context?.setStrokeColor(tintColor.cgColor)
        let pieceLength = bounds.width / Double(progress.count)

        var start: Double = 0
        var end: Double = 0
        var merged = false

        for iter in 0 ..< progress.count {
            start = Double(iter) * bounds.width / Double(progress.count)

            if !merged {
                context?.move(to: CGPoint(x: start, y: bounds.midY))
            }
            if progress[iter] == 1, iter != progress.count - 1 {
                merged = true
                continue
            }
            merged = false

            end = start + progress[iter] * pieceLength
            context?.addLine(to: CGPoint(x: end, y: bounds.midY))

            context?.strokePath()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        isOpaque = false
        #if os(visionOS)
        backgroundColor = .tertiarySystemFill
        #else
        backgroundColor = .systemFill
        #endif
    }

    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = defaultHeight / 2
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    let defaultHeight: Double = 4
}

public struct SegmentedProgressView: UIViewRepresentable {
    @Binding var progress: [Double]

    public func makeUIView(context: Context) -> UISegmentedProgressView {
        UISegmentedProgressView()
    }

    public func updateUIView(_ uiView: UISegmentedProgressView, context: Context) {
        uiView.progress = progress
    }
}
