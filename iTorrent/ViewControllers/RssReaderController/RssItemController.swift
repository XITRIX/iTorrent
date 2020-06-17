//
//  RssItemController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import MarqueeLabel
import UIKit
import WebKit

class RssItemController: ThemedUIViewController {
    override var toolBarIsHidden: Bool? {
        true
    }
    
    var webView: WKWebView!
    
    var model: RssItemModel!
    
    var themedHtmlPart: String {
        if Themes.currentTheme == .dark {
            return """
            <style>
            @media (prefers-color-scheme: dark) {
                body {
                    background-color: rgb(55,55,55);
                    color: white;
                }
                a:link {
                    color: rgb(255,76,43);
                }
                a:visited {
                    color: #9d57df;
                }
            }
            </style>
            """
        } else {
            return """
            <style>
            @media (prefers-color-scheme: light) {
                a:link {
                    color: rgb(255,76,43);
                }
                a:visited {
                    color: #9d57df;
                }
            }
            </style>
            """
        }
    }
    
    func setModel(_ model: RssItemModel) {
        self.model = model
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        webView.backgroundColor = Themes.current.backgroundSecondary
        
        loadHtml()
    }
    
    override func loadView() {
        super.loadView()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        let button = UIBarButtonItem(image: UIImage(named: "Share"), style: .plain, target: self, action: #selector(openLink))
        navigationItem.setRightBarButton(button, animated: false)
        
        webView = WKWebView(frame: view.frame)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = Themes.current.backgroundSecondary
        view.addSubview(webView)
        
        // MARQUEE LABEL
        let label = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.textColor = Themes.current.mainText
        label.trailingBuffer = 44
        label.text = model.title ?? ""
        navigationItem.titleView = label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.title
        
        webView.navigationDelegate = self
        loadHtml()
        
        if model.link.absoluteString.hasSuffix(".torrent") {
            Dialog.withButton(self, title: "RssItemController.PinTorrent", okTitle: "Download") {
                Core.shared.addFromUrl(self.model.link.absoluteString, presenter: self)
            }
        } else if TorrentSdk.getMagnetHash(magnetUrl: model.link.absoluteString) != nil {
            Dialog.withButton(self, title: "RssItemController.PinMagnet", okTitle: "Download") {
                TorrentSdk.addMagnet(magnetUrl: self.model.link.absoluteString)
            }
        }
    }
    
    func loadHtml() {
        if let description = model.description {
            let res = themedHtmlPart + description
            webView.loadHTMLString(res, baseURL: nil)
        }
    }
    
    @objc func openLink() {
        let dialog = ThemedUIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        dialog.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        let openInSafari = UIAlertAction(title: Localize.get("Open in Safari"), style: .default) { _ in
            UIApplication.shared.openURL(self.model.link)
        }
        let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)
        
        dialog.addAction(openInSafari)
        dialog.addAction(cancel)
        
        present(dialog, animated: true)
    }
}

extension RssItemController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
                UIApplication.shared.canOpenURL(url) {
                if url.absoluteString.hasSuffix(".torrent") {
                    Core.shared.addFromUrl(url.absoluteString, presenter: self)
                } else {
                    UIApplication.shared.openURL(url)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}
