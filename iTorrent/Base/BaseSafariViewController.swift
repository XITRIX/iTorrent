//
//  BaseSafariViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 31.05.2024.
//

import SafariServices

class BaseSafariViewController: SFSafariViewController {
    override init(url URL: URL, configuration: SFSafariViewController.Configuration = .init()) {
        super.init(url: URL, configuration: configuration)
        preferredControlTintColor = .tintColor
    }
}
