//
//  ThemedUITableViewCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUITableViewCell: UITableViewCell, Themed {
    private let cornerRadius: CGFloat = 12.0
    var insetStyle: Bool! = false
    private var tableView: UITableView!
    private var indexPath: IndexPath!
    
    override var frame: CGRect {
        get {
            if insetStyle {
                cutEdges(tableView: tableView, indexPath: indexPath)
            } else {
                self.layer.mask = nil
            }
            
            return super.frame
        }
        set (newFrame) {
            var frame = newFrame
            if insetStyle {
                var rightSafeareaInset: CGFloat = 0
                if #available(iOS 11, *) {
                    rightSafeareaInset = (UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0) > 0 ? 19 : 0
                }
                frame.origin.x += 25
                frame.size.width -= (50 + rightSafeareaInset)
            }
            super.frame = frame
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeUpdate()
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    @objc func themeUpdate() {
        let theme = Themes.current

        textLabel?.textColor = theme.mainText
        backgroundColor = theme.backgroundMain
    }
    
    func setInsetParams(tableView: UITableView, indexPath: IndexPath) {
        self.tableView = tableView
        self.indexPath = indexPath
    }
    
    private func cutEdges(tableView: UITableView, indexPath: IndexPath) {
        let layer: CAShapeLayer = CAShapeLayer()
        var path: CGMutablePath = CGMutablePath()

        if indexPath.row == 0 && indexPath.row == ( tableView.numberOfRows(inSection: indexPath.section) - 1) {
            addBothCorner(path)
            
        } else if indexPath.row == 0 {
            addUpperCorner(path)
        } else if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
            addBottonCorner(path)
        } else {
            path.addRect(bounds)
        }

        layer.path = path
        layer.fillRule = .nonZero
        self.layer.mask = layer
    }
    
    private func addUpperCorner(_ path: CGMutablePath) {
        let cornerRadius: CGFloat = 12.0
        
        path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        path.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.minY+1), tangent2End: CGPoint(x: bounds.midX, y: bounds.minY+1), radius: cornerRadius)
        path.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.minY+1), tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY), radius: cornerRadius)
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
    }
    
    private func addBottonCorner(_ path: CGMutablePath) {
        let cornerRadius: CGFloat = 12.0
        
        path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
        path.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.maxY-1), tangent2End: CGPoint(x: bounds.midX, y: bounds.maxY-1), radius: cornerRadius)
        path.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.maxY-1), tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY), radius: cornerRadius)
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
    }
    
    private func addBothCorner(_ path: CGMutablePath) {
        
        path.addPath(CGPath(roundedRect: CGRect(x: bounds.minX, y: bounds.minY+1, width: bounds.width, height: bounds.height-2), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
    }
}
