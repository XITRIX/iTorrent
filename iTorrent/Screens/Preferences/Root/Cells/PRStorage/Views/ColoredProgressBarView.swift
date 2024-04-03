//
//  ColoredProgressBarView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

@IBDesignable
class ColoredProgressBarView: UIView {
    var segments: [(color: UIColor, progress: Float)] = [(.systemOrange, 0.4), (.systemBlue, 0.3), (.systemGray, 0.25), (.systemGreen, 0.05)]

    public func setProgress(_ segments: [(color: UIColor, progress: Float)]) {
        self.segments = segments
        setNeedsDisplay()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(bounds.size.height)

        var drawPos: CGFloat = 0
        for (index, segment) in segments.enumerated() {
            context?.setStrokeColor(segment.color.cgColor)
            context?.move(to: CGPoint(x: drawPos, y: bounds.midY))
            let width = bounds.width * CGFloat(segment.progress)
            if width > 2 {
                drawPos += width
                if index != segments.count - 1 {
                    context?.addLine(to: CGPoint(x: drawPos - 1, y: bounds.midY))
                } else {
                    context?.addLine(to: CGPoint(x: bounds.size.width, y: bounds.midY))
                }
                context?.strokePath()
            }
        }
    }
}
