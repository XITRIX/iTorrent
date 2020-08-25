//
//  PortionBarLabels.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

@IBDesignable
class PortionBarLabels: UIView {
    typealias Item = (text: String, color: UIColor)
    
    var labels: [Item]? = [
        ("Episodes", .systemOrange),
        ("Artworks", .systemBlue),
        ("Cache", .systemGray),
        ("Configs", .systemGreen)
    ] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var colorIndicatorSize: CGSize = .init(width: 5, height: 5)
    
    @IBInspectable var colorIndicatorPaddings: CGFloat = 4
    
    /// Font used for the labels
    var textFont = UIFont.preferredFont(forTextStyle: .caption2)
    
    var textInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 6)
    
    var drawingTextAttributes: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: Themes.current.mainText,
            .font: textFont
        ]
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .redraw
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        if let labels = labels {
            renderLabels(labels, in: rect)
        }
    }
    
    private func renderLabels(_ labels: [Item], in rect: CGRect) {
        let midY = bounds.midY
        let indicatorYOffset = midY - (colorIndicatorSize.height / 2)
        let textAttributes = drawingTextAttributes
        var currentX: CGFloat = 0
        
        for (text, color) in labels {
            // Draw Indicator
            let indicatorFrame = CGRect(
                origin: .init(x: currentX + colorIndicatorPaddings, y: indicatorYOffset),
                size: colorIndicatorSize
            )
            let indicatorPath = UIBezierPath(ovalIn: indicatorFrame)
            color.setFill()
            indicatorPath.fill()
            
            currentX += (colorIndicatorPaddings * 2) + colorIndicatorSize.width
            
            // Draw Text
            let drawingText = text as NSString
            let estimatedTextSize = drawingText.size(withAttributes: textAttributes)
            currentX += textInsets.left
            drawingText.draw(
                at: .init(x: currentX, y: midY - (estimatedTextSize.height / 2)),
                withAttributes: textAttributes
            )
            currentX += estimatedTextSize.width + textInsets.right
        }
    }
}
