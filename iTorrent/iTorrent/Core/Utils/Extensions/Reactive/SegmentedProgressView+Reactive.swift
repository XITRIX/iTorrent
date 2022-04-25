//
//  SegmentedProgressView+Reactive.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 24.04.2022.
//

import Bond
import ReactiveKit
import UIKit

extension ReactiveExtensions where Base: SegmentedProgressView {
    var progress: Bond<[Float]> {
        return bond { $0.setProgress($1) }
    }
}

extension SegmentedProgressView: BindableProtocol {
    public func bind(signal: Signal<[Float], Never>) -> Disposable {
        return reactive.progress.bind(signal: signal)
    }
}
