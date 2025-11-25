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
    private var webView: WKWebView = .init()
    private var webViewViewController: UIViewController!
    @IBOutlet private var downloadButtonContainer: UIVisualEffectView!
    @IBOutlet private var downloadButtonNonSafeAreaHolder: UIView!
    @IBOutlet private var downloadButtonSeparator: UIView!
    @IBOutlet private var downloadButton: UIButton!
    @IBOutlet private var separatorHeight: NSLayoutConstraint!

    override var useMarqueeLabel: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webViewViewController.additionalSafeAreaInsets.bottom = downloadButtonNonSafeAreaHolder.bounds.height
    }

    private lazy var delegates = Delegates(parent: self)
}

private extension RssDetailsViewController {
    func setup() {
        navigationItem.largeTitleDisplayMode = .never
        setupDownloadButton()
        setupWebView()
        binding()

        webView.navigationDelegate = delegates
        loadHtml()
    }

    func binding() {
        disposeBag.bind {
            viewModel.$title.uiSink { [unowned self] text in
                title = text
            }
            viewModel.$downloadType.uiSink { [unowned self] downloadType in
                downloadButtonContainer.isHidden = downloadType == nil
                downloadButton.setTitle(downloadType?.title, for: .normal)
                downloadButton.isEnabled = downloadType != .added
                view.layoutSubviews()
            }
            downloadButton.tapPublisher.sink { [unowned self] _ in
                viewModel.download?()
            }
        }
    }

    func setupDownloadButton() {
        separatorHeight.constant = 1 / traitCollection.displayScale

        if #available(iOS 26, visionOS 26, *) {
            downloadButtonContainer.effect = nil
            downloadButtonSeparator.isHidden = true
            downloadButton.configuration = .prominentGlass()

            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = webView.scrollView
            interaction.edge = .bottom
            downloadButtonContainer.addInteraction(interaction)
        }

        downloadButton.configuration?.titleTextAttributesTransformer = .init { attributes in
            var result = attributes
            result.font = UIFont.preferredFont(forTextStyle: .headline)
            return result
        }
    }

    func setupWebView() {
        if let link = viewModel.rssModel.link,
           UIApplication.shared.canOpenURL(link)
        {
            let button = UIBarButtonItem(primaryAction: .init(image: .init(systemName: "safari"), handler: { [unowned self] _ in
                let safariVC = BaseSafariViewController(url: link)
                present(safariVC, animated: true)
            }))
            navigationItem.setRightBarButton(button, animated: false)
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.backgroundColor = .systemBackground
        webView.isOpaque = false

        webViewViewController = UIViewController()
        webViewViewController.view = webView

        addChild(webViewViewController)
        view.insertSubview(webView, at: 0)
        webViewViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false

        webViewViewController.additionalSafeAreaInsets.left = 8
        webViewViewController.additionalSafeAreaInsets.right = 8

        webView.backgroundColor = .systemBackground
#if !os(visionOS)
        webView.scrollView.keyboardDismissMode = .onDrag
#endif
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
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated
            else { return .allow }

            guard let url = navigationAction.request.url,
                  UIApplication.shared.canOpenURL(url)
            else { return .allow }

            Task { @MainActor in
                if let torrentFile = await TorrentFile(remote: url) {
                    TorrentAddViewModel.present(with: torrentFile, from: parent)
                } else if let magnet = MagnetURI(with: url) {
                    let alert = UIAlertController(title: %"list.add.magnet.title", message: nil, preferredStyle: .alert)
                    alert.addAction(.init(title: %"common.cancel", style: .cancel))
                    alert.addAction(.init(title: %"common.ok", style: .default, handler: { [self] _ in
                        if !TorrentService.shared.addTorrent(by: magnet) {
                            let alert = UIAlertController(title: %"addTorrent.exists", message: nil, preferredStyle: .alert)
                            alert.addAction(.init(title: %"common.ok", style: .cancel), isPrimary: true)
                            parent.present(alert, animated: true)
                        }
                    }), isPrimary: true)
                    parent.present(alert, animated: true)
                } else {
                    guard url.scheme == "http" || url.scheme == "https"
                    else {
                        print("Unsupported URL scheme")
                        return
                    }

                    let safari = BaseSafariViewController(url: url)
                    parent.present(safari, animated: true)
                }
            }

            return .cancel
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
