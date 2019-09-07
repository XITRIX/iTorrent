//
//  UpdateInfoCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class UpdateInfoCell : ThemedUITableViewCell, PreferenceCellProtocol {
    @IBOutlet var title: UILabel!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    var checked = false
    
    override func themeUpdate() {
        super.themeUpdate()
        loader?.style = Themes.current().loadingIndicatorStyle
    }
    
    func setModel(_ model: CellModelProtocol) {
        guard model is Model else { return }
        if (!checked) { checkUpdates() }
    }
    
    func checkUpdates() {
        title.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
        
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: "https://raw.githubusercontent.com/XITRIX/iTorrent/master/iTorrent/Version.ver") {
                do {
                    let remoteVersion = try String(contentsOf: url)
                    
                    let localurl = Bundle.main.url(forResource: "Version", withExtension: "ver")
                    let localVersion = try String(contentsOf: localurl!)
                    
                    DispatchQueue.main.async {
                        if (remoteVersion > localVersion) {
                            self.title.text = NSLocalizedString("New version ", comment: "") + remoteVersion + NSLocalizedString(" available", comment: "")
                            self.title.textColor = UIColor.red
                        } else if (remoteVersion < localVersion) {
                            self.title.text = NSLocalizedString("WOW, is it a new inDev build, huh?", comment: "")
                            self.title.textColor = UIColor.red
                        } else {
                            self.title.text = NSLocalizedString("Latest version installed", comment: "")
                        }
                        self.title.isHidden = false
                        self.loader.isHidden = true
                        self.loader.stopAnimating()
                        
                        self.checked = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.title.text = NSLocalizedString("Update check failed", comment: "")
                        self.title.isHidden = false
                        self.loader.isHidden = true
                        self.loader.stopAnimating()
                    }
                }
            }
        }
    }
    
    struct Model : CellModelProtocol {
        var reuseCellIdentifier: String = "UpdateInfoCell"
        var hiddenCondition: (() -> Bool)? = nil
        var tapAction : (()->())? = nil
    }
}
