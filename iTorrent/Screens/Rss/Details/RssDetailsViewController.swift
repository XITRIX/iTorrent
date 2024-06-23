//
//  RssDetailsViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import UIKit
import WebKit
import LibTorrent

class RssDetailsViewController<VM: RssDetailsViewModel>: BaseViewController<VM> {
    var webView: WKWebView!

    override func loadView() {
        let button = UIBarButtonItem(primaryAction: .init(image: .init(systemName: "safari"), handler: { [unowned self] _ in
            let safariVC = BaseSafariViewController(url: viewModel.rssModel.link)
            present(safariVC, animated: true)
        }))
        navigationItem.setRightBarButton(button, animated: false)

        webView = WKWebView()
        webView.backgroundColor = .secondarySystemBackground
#if !os(visionOS)
        webView.scrollView.keyboardDismissMode = .onDrag
#endif
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private lazy var delegates = Delegates(parent: self)
}

private extension RssDetailsViewController {
    func setup() {
        navigationItem.largeTitleDisplayMode = .never
        binding()

        webView.navigationDelegate = delegates
        loadHtml()
    }

    func binding() {
        disposeBag.bind {
            viewModel.$title.sink { [unowned self] text in
                title = text
            }
        }
    }

    func loadHtml() {
        if let description = viewModel.rssModel.description {
            let res = themedHtmlPart + description
            webView.loadHTMLString(res, baseURL: nil)
        }
    }
}

private extension RssDetailsViewController {
    class Delegates: DelegateObject<RssDetailsViewController>, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated
            else { return decisionHandler(.allow) }

            guard let url = navigationAction.request.url,
                  UIApplication.shared.canOpenURL(url)
            else { return decisionHandler(.allow) }

            Task {
                if let torrentFile = await TorrentFile(remote: url) {
                    TorrentAddViewModel.present(with: torrentFile, from: parent)
                } else {
                    let safari = await BaseSafariViewController(url: url)
                    await parent.present(safari, animated: true)
                }
            }
            
            decisionHandler(.cancel)
        }
    }
}

private extension RssDetailsViewController {
    var themedHtmlPart: String {
#if os(visionOS)
        return """
        <style>
        @media (prefers-color-scheme: dark) {
            body {
                background-color: \(UIColor.systemBackground.rgbString);
                color: white;
            }
            a:link {
                color: \(UIColor.tintColor.rgbString);
            }
            a:visited {
                color: #9d57df;
            }
        }
        </style>
        """
#else
        if traitCollection.userInterfaceStyle == .dark {
            return """
            <style>
            @media (prefers-color-scheme: dark) {
                body {
                    background-color: \(view.backgroundColor!.rgbString);
                    color: white;
                }
                a:link {
                    color: \(UIColor.tintColor.rgbString);
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
                    color: \(view.tintColor.rgbString);
                }
                a:visited {
                    color: #9d57df;
                }
            }
            </style>
            """
        }
#endif
    }
}

private extension UIColor {
    var rgbString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return "rgb(\(Int(red*255)),\(Int(green*255)),\(Int(blue*255)))"
    }
}
