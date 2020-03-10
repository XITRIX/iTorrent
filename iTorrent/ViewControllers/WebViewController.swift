//
//  WebViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    
    var webView: WKWebView!
    var url: URL!
    
    init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public static func present(in controller: UIViewController, with url: URL) {
        let web = controller.storyboard?.instantiateViewController(withIdentifier: "WebView") as! WebViewController
        web.url = url
        
        let nav = ThemedUINavigationController(rootViewController: web)
        nav.modalPresentationStyle = .fullScreen
        controller.present(nav, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isToolbarHidden = false
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false
        
        webView = WKWebView(frame: view.frame)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)

        webView.load(URLRequest(url: url))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            updateUI()
        }

        if (keyPath == "estimatedProgress") {
//            progressView.hidden = webView.estimatedProgress == 1
//            progressView.setProgress(Float(webView.estimatedProgress),  animated: true)
        }
    }
    
    func updateUI() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        title = webView.url?.host?.replacingOccurrences(of: "www.", with: "")
    }
    
    @IBAction func closeAction(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    @IBAction func backAction(_ sender: UIBarButtonItem) {
        webView.goBack()
        updateUI()
    }
    @IBAction func forwardAction(_ sender: UIBarButtonItem) {
        webView.goForward()
        updateUI()
    }
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
    }
    @IBAction func openInSafari(_ sender: UIBarButtonItem) {
    }
    
}
