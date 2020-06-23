//
//  KeyboardHelper.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class KeyboardHelper: NSObject {
    static let shared = KeyboardHelper()
    
    let animationDuration = Box<Double>(0)
    
    let frame = Box<CGRect>(.zero)
    let visibleHeight = Box<CGFloat>(0)
    let isHidden = Box<Bool>(true)
//    let willShowVisibleHeight = Box<CGFloat>(0)
    
    private let disposalBag = DisposalBag()
    private let panRecognizer: UIPanGestureRecognizer
    
    private let defaultFrame: CGRect
    private let frameVariable: Box<CGRect>
    
    override init() {
        defaultFrame = CGRect(
            x: 0,
            y: UIApplication.shared.keyWindow!.bounds.height,
            width: UIApplication.shared.keyWindow!.bounds.width,
            height: 0
        )
        frameVariable = Box<CGRect>(defaultFrame)
        panRecognizer = UIPanGestureRecognizer()
        super.init()
        
        panRecognizer.addTarget(self, action: #selector(pan))
        panRecognizer.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(frameChanged), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(frameHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        UIApplication.shared.keyWindow?.addGestureRecognizer(panRecognizer)
        
        frameVariable.bind { [weak self] frame in
            guard let self = self else { return }
            
            self.frame.variable = frame
            self.visibleHeight.variable = UIScreen.main.bounds.height - frame.origin.y
            self.isHidden.variable = self.visibleHeight.variable <= 0
            //            self.willShowVisibleHeight.variable =
        }.dispose(with: disposalBag)
    }
    
    @objc private func frameChanged(_ notification: Notification) {
        let time = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        animationDuration.variable = time?.doubleValue ?? 0
        
        let rectValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let frame = rectValue?.cgRectValue ?? defaultFrame
        if frame.origin.y < 0 { // if went to wrong frame
            var newFrame = frame
            newFrame.origin.y = UIApplication.shared.keyWindow!.bounds.height - newFrame.height
            frameVariable.variable = newFrame
        }
        frameVariable.variable = frame
    }
    
    @objc private func frameHide(_ notification: Notification) {
        let time = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        animationDuration.variable = time?.doubleValue ?? 0
        
        let rectValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let frame = rectValue?.cgRectValue ?? defaultFrame
        if frame.origin.y < 0 { // if went to wrong frame
            var newFrame = frame
            newFrame.origin.y = UIApplication.shared.keyWindow!.bounds.height
            frameVariable.variable = newFrame
        }
        frameVariable.variable = frame
    }
    
    @objc private func pan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.state == .changed,
            let window = UIApplication.shared.windows.first,
            frameVariable.variable.origin.y < UIApplication.shared.keyWindow!.bounds.height
        else { return }
        let origin = gestureRecognizer.location(in: window)
        var newFrame = frameVariable.variable
        newFrame.origin.y = max(origin.y, UIApplication.shared.keyWindow!.bounds.height - frameVariable.variable.height)
        frameVariable.variable = newFrame
    }
}

extension KeyboardHelper: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        let point = touch.location(in: gestureRecognizer.view)
        var view = gestureRecognizer.view?.hitTest(point, with: nil)
        while let candidate = view {
            if let scrollView = candidate as? UIScrollView,
                case .interactive = scrollView.keyboardDismissMode {
                return true
            }
            view = candidate.superview
        }
        return false
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer === panRecognizer
    }
}
