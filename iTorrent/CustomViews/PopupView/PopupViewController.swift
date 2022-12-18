//
//  PopupViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class PopupViewController: ThemedUIViewController {
    @IBOutlet var containerView: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var fxView: UIVisualEffectView!
    @IBOutlet var customButton: UIButton!
    @IBOutlet var bottomConstraint: NSLayoutConstraint! {
        didSet {
            bottomConstraint.constant = bottomExtraSpacer + Utils.safeAreaInsets.bottom
        }
    }
    
    var dismissAction: (() -> ())?
    var customAction: (() -> ())?

    private var contentController: UIViewController?
    private var contentView: UIView
    private var contentHeight: CGFloat
    
    private let bottomExtraSpacer: CGFloat = 88
    private var baseYPosition: CGFloat? {
        if let superview = view.superview {
            return superview.frame.height - view.frame.height + bottomExtraSpacer
        }
        return nil
    }
    
    init(_ content: UIViewController, contentHeight: CGFloat) {
        self.contentController = content
        self.contentView = content.view
        self.contentHeight = contentHeight
        
        super.init(nibName: String(describing: PopupViewController.self), bundle: Bundle.main)
    }
    
    init(_ content: UIView, contentHeight: CGFloat) {
        self.contentView = content
        self.contentHeight = contentHeight
        
        super.init(nibName: String(describing: PopupViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        view.backgroundColor = .clear
        
        let theme = Themes.current
        fxView.effect = UIBlurEffect(style: theme.blurEffect)
        if #available(iOS 11, *) {
        } else {
            fxView.backgroundColor = theme.backgroundMain
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 5
        
        fxView.layer.cornerRadius = 12
        
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(contentView)
        
        if let controller = contentController {
            addChild(controller)
            controller.didMove(toParent: self)
        }
        
        contentView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        
        headerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panAction(_:))))
    }
    
    func show(in viewController: UIViewController) {
        viewController.view.addSubview(view)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.addChild(self)
        didMove(toParent: viewController)
        
        view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor, constant: bottomExtraSpacer).isActive = true
        view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor).isActive = true
        
        view.frame.origin.y = viewController.view.frame.height
        UIView.animate(withDuration: 0.4, delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                           self.view.frame.origin.y = self.baseYPosition!
                       })
    }
    
    @objc func panAction(_ sender: UIPanGestureRecognizer) {
        if view.superview != nil {
            let translation = sender.translation(in: view)
            let newOrigin = CGPoint(x: view.frame.origin.x, y: view.frame.origin.y + translation.y)
            if newOrigin.y > baseYPosition! {
                view.frame.origin = newOrigin
                sender.setTranslation(CGPoint.zero, in: view)
            } else {
                view.frame.origin.y = baseYPosition!
            }
            if sender.state == .ended {
                if sender.velocity(in: view).y > 0 {
                    dismiss()
                } else {
                    UIView.animate(withDuration: 0.4, delay: 0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 0,
                                   options: .curveEaseInOut,
                                   animations: {
                                       self.view.frame.origin.y = self.baseYPosition!
                                   })
                }
            }
        }
    }
    
    @IBAction func customButtonAction(_ sender: UIButton) {
        customAction?()
    }
    
    @IBAction func dismissAction(_ sender: UIButton) {
        dismiss()
    }
    
    func dismiss(animationOnly: Bool = false) {
        if !(view.superview?.subviews.contains(view) ?? false) { return }
        
        if !animationOnly {
            dismissAction?()
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint.constant -= self.view.frame.height
            self.view.superview?.layoutIfNeeded()
        }) { _ in
            self.view.removeFromSuperview()
            self.didMove(toParent: nil)
        }
    }
}
