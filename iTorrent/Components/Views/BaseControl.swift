//
//  BaseControl.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.05.2024.
//

import UIKit
import MvvmFoundation

public class BaseControl: UIControl {
    public init() {
        super.init(frame: .zero)
        commonInit()
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
        setup()
    }

    open func setup() { /* Override to setup view */ }
    public var disposeBag = DisposeBag()
}

private extension BaseControl {
    func commonInit() {
        let nibName = "\(Self.self)"

        guard Bundle.main.path(forResource: nibName, ofType: "nib") != nil
        else { return }

        let nib = Bundle.main.loadNibNamed(nibName, owner: self)

        guard let view = nib?.first as? UIView else { return }
        let targetContainer = self

        view.translatesAutoresizingMaskIntoConstraints = false
        view.preservesSuperviewLayoutMargins = true
        view.backgroundColor = .clear
        targetContainer.addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: targetContainer.leadingAnchor),
            view.topAnchor.constraint(equalTo: targetContainer.topAnchor),
            targetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            targetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

