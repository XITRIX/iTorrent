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
    private weak var tableView: UITableView?
    private var indexPath: IndexPath!

    override var frame: CGRect {
        get {
            super.frame
        }
        set {
            var frame = newValue
            if insetStyle {
                let left = tableView?.layoutMargins.left ?? 0
                let right = tableView?.layoutMargins.right ?? 0

                frame.origin.x += left
                frame.size.width -= left + right
            }
            super.frame = frame

            if #available(iOS 11, *) {
                cornerRadiusMask(tableView: tableView, indexPath: indexPath)
            } else {
                layer.mask = cutEdgesMask(tableView: tableView, indexPath: indexPath)
            }
        }
    }

    var defaultMargins: UIEdgeInsets {
        let res: UIEdgeInsets

        if #available(iOS 11.0, *) {
            let system = tableView?.parentViewController?.systemMinimumLayoutMargins
            if let system, system != .zero {
                res = UIEdgeInsets(system)
            } else {
                res = tableView?.layoutMargins ?? .init(top: 0, left: 16, bottom: 0, right: 16)
            }
        } else {
            res = .init(top: 0, left: 16, bottom: 0, right: 16)
        }

        return res
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    override var layoutMargins: UIEdgeInsets {
        get { defaultMargins }
        set { super.layoutMargins = defaultMargins }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    @objc func themeUpdate() {
        let theme = Themes.current

        textLabel?.textColor = theme.mainText

        let bgColorView = UIView()
        if tableView?.style == .plain {
            backgroundColor = theme.backgroundMain
            bgColorView.backgroundColor = theme.backgroundSecondary
        } else {
            backgroundColor = theme.groupedBackgroundSecondary
            bgColorView.backgroundColor = theme.backgroundSecondary
        }
        selectedBackgroundView = bgColorView
    }

    func setInsetParams(tableView: UITableView, indexPath: IndexPath) {
        self.tableView = tableView
        self.indexPath = indexPath
    }

    func setTableView(_ tableView: UITableView) {
        self.tableView = tableView
        themeUpdate()
    }

    // Remove section top and bottom separators
    override func layoutSubviews() {
        super.layoutSubviews()

        for subview in subviews {
            if subview != contentView, subview.frame.height < 3 {
                if subview.frame.width == frame.width {
                    subview.isHidden = insetStyle
                } else {
                    let margins = defaultMargins
                    let subviewFrame = subview.frame
                    subview.frame = .init(x: margins.left, y: subviewFrame.minY, width: frame.width - margins.left, height: subviewFrame.height)
                    subview.isHidden = false
                }
            }
        }
    }

    @available(iOS 11.0, *)
    private func cornerRadiusMask(tableView: UITableView?, indexPath: IndexPath?) {
        guard insetStyle,
              let tableView = tableView,
              let indexPath = indexPath,
              indexPath.section < tableView.numberOfSections,
              indexPath.row < tableView.numberOfRows(inSection: indexPath.section)
        else { return }

        layer.cornerRadius = cornerRadius
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }

        if indexPath.row == 0, indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        } else if indexPath.row == 0 {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            layer.maskedCorners = []
        }
    }

    private func cutEdgesMask(tableView: UITableView?, indexPath: IndexPath?) -> CALayer? {
        guard insetStyle,
              let tableView = tableView,
              let indexPath = indexPath,
              indexPath.section < tableView.numberOfSections,
              indexPath.row < tableView.numberOfRows(inSection: indexPath.section)
        else { return nil }

        let layer = CAShapeLayer()
        let path = CGMutablePath()

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
        return layer
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
