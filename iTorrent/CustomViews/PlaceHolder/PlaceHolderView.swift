//
//  PlaceHolderView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class PlaceHolderView: ThemedUIView {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textLabel: ThemedUILabel!
    
    override func themeUpdate() {
        super.themeUpdate()
        
        let theme = Themes.current
        backgroundColor = theme.backgroundMain
        imageView.tintColor = theme.secondaryText
    }
    
    public static func fromNib() -> PlaceHolderView {
        let nib = UINib(nibName: "PlaceHolderView", bundle: Bundle.main)
        return nib.instantiate(withOwner: self, options: nil).first as! PlaceHolderView
    }
}
