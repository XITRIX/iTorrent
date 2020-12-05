//
//  UIImageViewExtensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

fileprivate var cache = NSCache<NSURL, UIImage>()

extension UIImageView {
    func load(url: URL, placeholder: UIImage? = nil) {
        if let cachedImage = cache.object(forKey: url as NSURL) {
            self.image = cachedImage
        } else {
            if let placeholderImage = placeholder {
                self.image = placeholderImage
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                if let data = try? Data(contentsOf: url) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cache.setObject(image, forKey: url as NSURL)
                            self?.image = image
                        }
                    }
                }
            }
        }
    }
}
