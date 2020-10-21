//
//  PopupView.swift
//  PopupView
//
//  Created by Daniil Vinogradov on 03.09.2019.
//  Copyright © 2019 NoNameDude. All rights reserved.
//

import UIKit

class PopupView: ThemedUIView {
    @IBOutlet var mainView: UIView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var fxView: UIVisualEffectView!
    @IBOutlet var dismissButton: UIButton!
    @IBOutlet var customButton: UIButton!
    @IBOutlet var bottomOffsetConstraint: NSLayoutConstraint! {
        didSet {
            bottomOffsetConstraint.constant = bottomOffset // + Utils.safeAreaInsets.bottom
        }
    }

    private let bottomOffset: CGFloat = 44
    private var bottomConstraint: NSLayoutConstraint?
    private var initViewPos: CGRect!

    var contentView: UIView!
    var contentHeight: CGFloat!
    var dismissAction: (() -> ())?
    var customAction: (() -> ())?

    var vc: UIViewController?

    init(contentView: UIView, contentHeight: CGFloat, customAction: (() -> ())? = nil, dismissAction: (() -> ())? = nil) {
        super.init(frame: CGRect.zero)
        commonInit()
        self.contentHeight = contentHeight
        self.dismissAction = dismissAction
        self.customAction = customAction
        setContentView(contentView: contentView)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mainView.roundCorners(corners: [.topLeft, .topRight], radius: 12)
    }

    private func setContentView(contentView: UIView) {
        self.contentView = contentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        contentView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

        NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: contentHeight).isActive = true
    }

    func commonInit() {
        Bundle.main.loadNibNamed("PopupView", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = bounds
        translatesAutoresizingMaskIntoConstraints = false

        let image = #imageLiteral(resourceName: "Close").withRenderingMode(.alwaysTemplate) // dismissButton.currentImage?.withRenderingMode(.alwaysTemplate)
        dismissButton.setImage(image, for: .normal)

        headerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panAction(_:))))
    }

    func show(_ vc: UIViewController?) {
        guard let vc = vc else { return }

        self.vc = vc
        vc.view.addSubview(self)

        let viewHeight = contentHeight + headerView.frame.height + bottomOffset + Utils.safeAreaInsets.bottom

        centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
        widthAnchor.constraint(equalTo: vc.view.widthAnchor).isActive = true
        bottomConstraint = bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: viewHeight)
        bottomConstraint?.isActive = true
        vc.view.layoutIfNeeded()

        layer.shadowOpacity = 0.3
        layer.shadowRadius = 5

        UIView.animate(withDuration: 0.4, delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                           self.bottomConstraint?.constant = self.bottomOffset
                           vc.view.layoutIfNeeded()
                           self.initViewPos = self.frame
                       })
    }

    @IBAction func customButtonAction(_ sender: Any) {
        customAction?()
    }

    @IBAction func dismissButtonAction(_ sender: Any) {
        dismiss()
    }

    @objc func panAction(_ sender: UIPanGestureRecognizer) {
        if let vc = vc {
            let translation = sender.translation(in: self)
            let newOrigin = CGPoint(x: frame.origin.x, y: frame.origin.y + translation.y)
            if newOrigin.y + frame.height - bottomOffset > vc.view.frame.height {
                frame.origin = newOrigin
                sender.setTranslation(CGPoint.zero, in: self)
            } else {
                frame.origin.y = vc.view.frame.height - frame.height + bottomOffset
            }
            if sender.state == .ended {
                if sender.velocity(in: self).y > 0 {
                    dismiss()
                } else {
                    UIView.animate(withDuration: 0.4, delay: 0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 0,
                                   options: .curveEaseInOut,
                                   animations: {
                                       self.frame.origin.y = vc.view.frame.height - self.frame.height + self.bottomOffset
                                       self.bottomConstraint?.constant = self.bottomOffset
                                       vc.view.layoutIfNeeded()
                                   })
                }
            }
        }
    }

    @objc func dismiss() {
        dismiss(animationOnly: false)
    }

    @objc func dismiss(animationOnly: Bool = false) {
        if !(superview?.subviews.contains(self) ?? false) { return }

        if !animationOnly {
            dismissAction?()
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint?.constant += self.frame.height
            self.vc?.view.layoutIfNeeded()
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
