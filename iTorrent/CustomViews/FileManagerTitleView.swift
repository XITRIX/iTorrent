//
//  FileManagerTitleView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 12/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

import MarqueeLabel

@IBDesignable
class FileManagerTitleView: UIView, Themed {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var title: MarqueeLabel!
    @IBOutlet weak var subTitle: MarqueeLabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)

        Bundle.main.loadNibNamed("FileManagerTitleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        themeUpdate()
    }

    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView

        return view!
    }

    @objc func themeUpdate() {
        let theme = Themes.current
        title?.textColor = theme.mainText
        subTitle?.textColor = theme.tertiaryText
    }
}
