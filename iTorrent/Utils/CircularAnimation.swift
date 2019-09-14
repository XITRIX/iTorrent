//
//  CircularAnimation.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class CircularAnimation {
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
        
        view.rootViewController?.present(imgVC, animated: false, completion: {
            UIView.animate(withDuration: 0.3, animations: {
                circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            }) { _ in
                imgVC.dismiss(animated: false)
            }
        })
    }
    
    private static func frameForCircle (withViewCenter viewCenter:CGPoint, size viewSize:CGSize, startPoint:CGPoint) -> CGRect {
        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)
        
        let offestVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offestVector, height: offestVector)
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
}
