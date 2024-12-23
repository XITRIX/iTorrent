//
//  CircularAnimation.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class CircularAnimation {
    @MainActor
    public static func animate(startingPoint: CGPoint, animation: () -> Void, completion: @escaping () -> Void) {
        let windowScene = UIApplication.shared
            .connectedScenes
            .first

        guard let windowScene = windowScene as? UIWindowScene,
              let view = windowScene.keyWindow
        else { return }

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

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .statusBar + 1
        window.backgroundColor = .clear
        window.rootViewController = imgVC
        window.isHidden = false

        animation()
        UIView.animate(withDuration: 0.3, animations: {
            circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }) { [window] _ in
            window.isHidden = true
            completion()
        }
    }

    private static func frameForCircle(withViewCenter viewCenter: CGPoint, size viewSize: CGSize, startPoint: CGPoint) -> CGRect {
        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)

        let offsetVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offsetVector, height: offsetVector)

        return .init(origin: .zero, size: size)
    }
}
