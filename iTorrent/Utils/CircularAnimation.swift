//
//  CircularAnimation.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class CircularAnimation {
    private static var window: UIWindow?

    public static func animate(startingPoint: CGPoint) {
        let view = UIApplication.shared.keyWindow!

        let snapshot = view.snapshotView(afterScreenUpdates: true)!
        let imgVC = UIViewController()
        imgVC.modalPresentationStyle = .overFullScreen
        imgVC.modalPresentationCapturesStatusBarAppearance = false

        imgVC.view.addSubview(snapshot)

        let circle = UIView()
        circle.frame = frameForCircle(withViewCenter: view.center, size: view.bounds.size, startPoint: startingPoint)
        circle.layer.cornerRadius = circle.frame.size.height / 2
        circle.center = startingPoint
        circle.backgroundColor = .blue

        snapshot.mask = circle

        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared
                .connectedScenes
                .filter {
                $0.activationState == .foregroundActive
            }
                .first

            if let windowScene = windowScene as? UIWindowScene {
                window = UIWindow(windowScene: windowScene)
            }
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window?.windowLevel = .statusBar + 1
        window?.backgroundColor = .clear
        window?.rootViewController = imgVC
        window?.isHidden = false

        NotificationCenter.default.post(name: Themes.updateNotification, object: nil)
        UIView.animate(withDuration: 0.3, animations: {
            circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }) { _ in
            window?.isHidden = true
            window = nil
        }
    }

    private static func frameForCircle(withViewCenter viewCenter: CGPoint, size viewSize: CGSize, startPoint: CGPoint) -> CGRect {
        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)

        let offsetVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offsetVector, height: offsetVector)

        return CGRect(origin: CGPoint.zero, size: size)
    }
}
