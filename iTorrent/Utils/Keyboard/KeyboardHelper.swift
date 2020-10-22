//
//  KeyboardHelper.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond
import UIKit
import ReactiveKit

class KeyboardHelper: NSObject {
    static let shared = KeyboardHelper()
    
    let animationDuration = Observable<Double>(0)
    
    let frame = Observable<CGRect>(.zero)
    let visibleHeight = Observable<CGFloat>(0)
    let isHidden = Observable<Bool>(true)
//    let willShowVisibleHeight = Box<CGFloat>(0)
    
    private let disposalBag = DisposeBag()
    private let panRecognizer: UIPanGestureRecognizer
    
    private let defaultFrame: CGRect
    private let frameVariable: Observable<CGRect>
    
    override init() {
        defaultFrame = CGRect(
            x: 0,
            y: UIApplication.shared.keyWindow!.bounds.height,
            width: UIApplication.shared.keyWindow!.bounds.width,
            height: 0
        )
        frameVariable = Observable<CGRect>(defaultFrame)
        panRecognizer = UIPanGestureRecognizer()
        super.init()
        
        panRecognizer.addTarget(self, action: #selector(pan))
        panRecognizer.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(frameChanged), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(frameHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        UIApplication.shared.keyWindow?.addGestureRecognizer(panRecognizer)
        
        frameVariable.observeNext { [weak self] frame in
            guard let self = self else { return }

            self.frame.value = frame
            self.visibleHeight.value = max(UIApplication.shared.keyWindow!.bounds.height - frame.origin.y, 0)
            self.isHidden.value = self.visibleHeight.value <= 0
        }.dispose(in: disposalBag)
    }
    
    @objc private func frameChanged(_ notification: Notification) {
        let time = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        animationDuration.value = time?.doubleValue ?? 0
        
        let rectValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let frame = rectValue?.cgRectValue ?? defaultFrame
        if frame.origin.y < 0 { // if went to wrong frame
            var newFrame = frame
            newFrame.origin.y = UIApplication.shared.keyWindow!.bounds.height - newFrame.height
            frameVariable.value = newFrame
        }
        frameVariable.value = frame
    }
    
    @objc private func frameHide(_ notification: Notification) {
        let time = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        animationDuration.value = time?.doubleValue ?? 0
        
        let rectValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let frame = rectValue?.cgRectValue ?? defaultFrame
        if frame.origin.y < 0 { // if went to wrong frame
            var newFrame = frame
            newFrame.origin.y = UIApplication.shared.keyWindow!.bounds.height
            frameVariable.value = newFrame
        }
        frameVariable.value = frame
    }
    
    @objc private func pan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.state == .changed,
            let window = UIApplication.shared.windows.first,
            frameVariable.value.origin.y < UIApplication.shared.keyWindow!.bounds.height
        else { return }
        let origin = gestureRecognizer.location(in: window)
        var newFrame = frameVariable.value
        newFrame.origin.y = max(origin.y, UIApplication.shared.keyWindow!.bounds.height - frameVariable.value.height)
        frameVariable.value = newFrame
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
        gestureRecognizer === panRecognizer
    }
}
