//
//  PopupView.swift
//  PopupView
//
//  Created by Daniil Vinogradov on 03.09.2019.
//  Copyright © 2019 NoNameDude. All rights reserved.
//

import UIKit

class PopupView : UIView {
    @IBOutlet var mainView: UIView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var fxView: UIVisualEffectView!
    @IBOutlet var dismissButton: UIButton!
    @IBOutlet var bottomOffsetConstraint: NSLayoutConstraint! {
        didSet {
            bottomOffsetConstraint.constant = bottomOffset
        }
    }
    
    private let bottomOffset: CGFloat = 44
    private var bottomConstraint: NSLayoutConstraint?
    private var initViewPos: CGRect!
    
    var contentView: UIView!
    var contentHeight: CGFloat!
    var dismissAction: (()->())?
    
    var vc : UIViewController?
    
    init(contentView: UIView, contentHeight: CGFloat, dismissAction: (()->())? = nil) {
        super.init(frame: CGRect.zero)
        cummonInit()
        self.contentHeight = contentHeight
        self.dismissAction = dismissAction
        setContentView(contentView: contentView)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cummonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        cummonInit()
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
    
    func cummonInit() {
        Bundle.main.loadNibNamed("PopupView", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = self.bounds
        translatesAutoresizingMaskIntoConstraints = false
        
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        let image = #imageLiteral(resourceName: "Close").withRenderingMode(.alwaysTemplate) //dismissButton.currentImage?.withRenderingMode(.alwaysTemplate)
        dismissButton.setImage(image, for: .normal)
        
        headerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panAction(_:))))
    }
    
    func show(_ vc: UIViewController) {
        self.vc = vc
        vc.view.addSubview(self)
        
        let viewHeight = contentHeight + headerView.frame.height + bottomOffset
        
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
    
    @IBAction func dismissButtonAction(_ sender: Any) {
        dismiss()
    }
    
    @objc func panAction(_ sender:UIPanGestureRecognizer) {
        if let vc = vc {
            let translation = sender.translation(in: self)
            let newOrigin = CGPoint(x: self.frame.origin.x, y: self.frame.origin.y + translation.y)
            if (newOrigin.y + self.frame.height - bottomOffset > vc.view.frame.height) {
                self.frame.origin = newOrigin
                sender.setTranslation(CGPoint.zero, in: self)
            } else {
                self.frame.origin.y = vc.view.frame.height - self.frame.height + bottomOffset
            }
            if sender.state == .ended {
                if (sender.velocity(in: self).y > 0) {
                    dismiss()
                }
                else {
                    UIView.animate(withDuration: 0.4, delay: 0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 0,
                                   options: .curveEaseInOut,
                                   animations: {
                                    self.frame.origin.y = self.initViewPos.origin.y
                                       self.bottomConstraint?.constant = self.bottomOffset
                                       vc.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    @objc func dismiss() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint?.constant += self.frame.height
            self.vc?.view.layoutIfNeeded()
        }) { _ in
            self.dismissAction?()
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
