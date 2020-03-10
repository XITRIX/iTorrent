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
        set(newFrame) {
            var frame = newFrame
            if insetStyle {
                var rightSafeareaInset: CGFloat = 0
                if #available(iOS 11, *) {
                    rightSafeareaInset = (UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0) > 0 ? 23 : 0
                }
                frame.origin.x += 21
                frame.size.width -= (42 + rightSafeareaInset)
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
        let path: CGMutablePath = CGMutablePath()

        if indexPath.row == 0, indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
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
        path.addPath(UIBezierPath(roundedRect: CGRect(x: bounds.minX, y: bounds.minY + 1, width: bounds.width, height: bounds.height - 1),
                                  byRoundingCorners: [.topLeft, .topRight],
                                  cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath)
    }

    private func addBottonCorner(_ path: CGMutablePath) {
        path.addPath(UIBezierPath(roundedRect: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height - 1),
                                  byRoundingCorners: [.bottomLeft, .bottomRight],
                                  cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath)
    }

    private func addBothCorner(_ path: CGMutablePath) {
        path.addPath(UIBezierPath(roundedRect: CGRect(x: bounds.minX, y: bounds.minY + 1, width: bounds.width, height: bounds.height - 2),
                                  byRoundingCorners: .allCorners,
                                  cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath)
    }
}
