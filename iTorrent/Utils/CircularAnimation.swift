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
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        view.layer.render(in: context)

        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let img = UIImageView(image: viewImage, highlightedImage: viewImage)
        
        let imgVC = UIViewController()
        imgVC.view.addSubview(img)
        window = UIWindow(frame: view.bounds)
        window?.windowLevel = UIWindow.Level.statusBar + 1
        window?.rootViewController = imgVC
        window?.isHidden = false
        
        let circle = UIView()
        circle.frame = frameForCircle(withViewCenter: view.center, size: view.bounds.size, startPoint: startingPoint)
        circle.layer.cornerRadius = circle.frame.size.height / 2
        circle.center = startingPoint
        circle.backgroundColor = .blue
        
        img.mask = circle
        
        UIView.animate(withDuration: 0.3, animations: {
//            window?.alpha = 0
//            circle.transform = CGAffineTransform.identity
            circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }) { _ in
            window?.isHidden = true
            window = nil
        }
    }
    
    private static func frameForCircle (withViewCenter viewCenter:CGPoint, size viewSize:CGSize, startPoint:CGPoint) -> CGRect {
        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)
        
        let offestVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offestVector, height: offestVector)
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
}
