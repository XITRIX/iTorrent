//
//  TagsView.swift
//  Apple-Music-Search-Chips-Demo
//
//  Created by Seb Vidal on 07/09/2024.
//  Modified by XITRIX on 14/11/2024.
//

import Combine
import UIKit

class TagsView: UIScrollView {
    private var lastUpdatedFrame: CGRect = .zero
    private var bottomStackView: UIStackView!
    private var topStackView: UIStackView!
    private var backgroundView: UIView!
    private var tagMaskView: UIView!

    var titles: [String] = [] {
        didSet { updateButtons(for: titles) }
    }

    @Published var selectedTagIndex: Int = 0 {
        didSet {
            updateSelection(for: selectedTagIndex, animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
        setupBottomStackView()
        setupTopStackView()
        setupBackgroundView()
        setupTagMaskView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func scrollToSelectedItem() {
        let button = bottomStackView.arrangedSubviews[selectedTagIndex]
        scrollRectToVisible(button.frame, animated: true)
    }

    private func setupScrollView() {
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .automatic
    }

    private func setupBottomStackView() {
        bottomStackView = UIStackView()
        bottomStackView.axis = .horizontal
        bottomStackView.distribution = .fillProportionally
        bottomStackView.isLayoutMarginsRelativeArrangement = true
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bottomStackView)

        NSLayoutConstraint.activate([
            bottomStackView.topAnchor.constraint(equalTo: topAnchor),
            bottomStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupTopStackView() {
        topStackView = UIStackView()
        topStackView.axis = .horizontal
        topStackView.isUserInteractionEnabled = false
        topStackView.distribution = .fillProportionally
        topStackView.isLayoutMarginsRelativeArrangement = true
        topStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(topStackView)

        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor),
            topStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupBackgroundView() {
#if os(iOS)
        if #available(iOS 26, *) {
            let effect = UIGlassEffect()
//            effect.isInteractive = true
            effect.tintColor = .tintColor

            backgroundView = UIVisualEffectView(effect: effect)
            backgroundView.clipsToBounds = true
            backgroundView.layer.cornerCurve = .continuous
        } else {
            backgroundView = UIView()
            backgroundView.clipsToBounds = true
            backgroundView.backgroundColor = .tintColor
            backgroundView.layer.cornerCurve = .continuous
        }
#else
        backgroundView = UIView()
        backgroundView.clipsToBounds = true
        backgroundView.backgroundColor = PreferencesStorage.shared.tintColor
        backgroundView.layer.cornerCurve = .continuous
#endif

        insertSubview(backgroundView, aboveSubview: bottomStackView)
    }

    private func setupTagMaskView() {
        tagMaskView = UIView()
        tagMaskView.clipsToBounds = true
        tagMaskView.backgroundColor = .black
        tagMaskView.layer.cornerCurve = .continuous

        topStackView.mask = tagMaskView
    }

    private func updateButtons(for titles: [String]) {
        bottomStackView.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        topStackView.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        for title in titles {
            let bottomButton = button(with: title, foregroundColor: .label)
            bottomStackView.addArrangedSubview(bottomButton)

            let topButton = button(with: title, foregroundColor: .white)
            topStackView.addArrangedSubview(topButton)
        }

        setNeedsLayout()
        layoutIfNeeded()

        updateSelection(for: selectedTagIndex, animated: false)
    }

    private func button(with title: String, foregroundColor: UIColor) -> UIButton {
        let titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { container in
            var container = container
            container.font = UIFont.systemFont(ofSize: 13, weight: .semibold)

            return container
        }

        let button = UIButton(type: .system)
        button.configuration = .plain()
        button.configuration?.title = title
        button.configuration?.cornerStyle = .capsule
        button.configuration?.baseForegroundColor = foregroundColor
        button.configuration?.titleTextAttributesTransformer = titleTextAttributesTransformer
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 8.33, leading: 12, bottom: 8, trailing: 12.66)
        button.addTarget(self, action: #selector(tagButtonTapped), for: .touchUpInside)

        return button
    }

    @objc private func tagButtonTapped(_ sender: UIButton) {
        selectedTagIndex = bottomStackView.arrangedSubviews.firstIndex(of: sender)!
    }

    private func updateSelection(for selectedTagIndex: Int, animated: Bool) {
        let update = { [self] in
            if bottomStackView.arrangedSubviews.indices.contains(selectedTagIndex) {
                let button = bottomStackView.arrangedSubviews[selectedTagIndex]

                tagMaskView.layer.cornerRadius = button.frame.height / 2
                tagMaskView.frame = button.frame

                backgroundView.layer.cornerRadius = button.frame.height / 2
                backgroundView.frame = button.frame

                scrollRectToVisible(button.frame, animated: true)
            }
        }

        guard animated
        else { return update() }

        if #available(iOS 17.0, *) {
            UIView.animate(springDuration: 0.25, bounce: 0.25) {
                update()
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                update()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard backgroundView.frame == .zero
        else { return }

        updateSelection(for: selectedTagIndex, animated: false)
    }
}
