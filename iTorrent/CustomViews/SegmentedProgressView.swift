//
//  SegmentedProgressView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 09/06/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class SegmentedProgressView: UIView, Themed {
    var numPiecesOld = 0
    var numPieces: Int = 0
    
    private var progress: [CGFloat] = []
    
    public func setNumberOfSections(_ sections: Int) {
        if (numPiecesOld == sections) { return }
        
        numPiecesOld = numPieces
        progress = [CGFloat].init(repeating: 0, count: numPieces)
    }
    
    public func setProgress(_ progress: [Float]) {
        setProgress(progress.map{ CGFloat($0) })
    }
    
    public func setProgress(_ progress: [CGFloat]) {
        if (self.progress == progress) { return }
        
        numPieces = progress.count
        self.progress = progress
        setNeedsDisplay()
    }
    
    public func setProgress(_ progress: Float, pieceIndex: Int) {
        self.progress[pieceIndex] = CGFloat(progress)
        setNeedsDisplay()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
//        backgroundColor = Themes.current().progressBarBackground
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = true
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(bounds.size.height)
        context?.setStrokeColor(tintColor.cgColor)
        let pieceLength = bounds.width / CGFloat(numPieces)
        
        var start: CGFloat = 0
        var end: CGFloat = 0
        var merged = false
        
        for i in 0 ..< numPieces {
            start = CGFloat(i) * bounds.width / CGFloat(numPieces)
            
            if (!merged) {
                context?.move(to: CGPoint(x: start, y: bounds.midY))
            }
            if (progress[i] == 1 && i != numPieces - 1) {
                merged = true
                continue
            }
            merged = false
            
            end = start + progress[i] * pieceLength
            context?.addLine(to: CGPoint(x: end, y: bounds.midY))
            
            context?.strokePath()
        }
    }
}
