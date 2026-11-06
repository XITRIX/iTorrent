//
//  PatreonPreferencesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import Combine
import SafariServices
import UIKit

class PatreonPreferencesViewController<VM: PatreonPreferencesViewModel>: BaseViewController<VM> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var roundedViews: [UIView]!

    @IBOutlet private var creatorName: UILabel!
    @IBOutlet private var creatorDescription: UILabel!
    @IBOutlet private var creatorMessage: UILabel!

    @IBOutlet private var patronBox: UIView!
    @IBOutlet private var patronTitle: UILabel!
    @IBOutlet private var patronMessage: UILabel!

    @IBOutlet private var becomePatronButton: UIButton!
    @IBOutlet private var linkPatreonButton: UIButton!
    @IBOutlet private var linkPatreonLoading: UIActivityIndicatorView!

    @IBOutlet private var chatPin: UIImageView!

    @IBOutlet private var supportersSection: UIStackView!
    @IBOutlet private var supportersCollection: UICollectionView!
    @IBOutlet private var supportersHeight: NSLayoutConstraint!

    private let supportersDataSource = SupportersDataSource()
    private var supportersSizeObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = %"preferences.donations.patreon"

        roundedViews.forEach {
#if os(visionOS)
            $0.layer.cornerRadius = 16
#else
            if #available(iOS 26, *) {
                $0.layer.cornerRadius = 26
            } else {
                $0.layer.cornerRadius = 10
            }
#endif
            $0.layer.cornerCurve = .continuous
        }

        creatorName.text = %"patreon.creator.name"
        creatorDescription.text = %"patreon.creator.description"
        creatorMessage.text = %"patreon.creator.message"

        patronMessage.text = %"patreon.patron.level"

#if !os(visionOS)
        if #available(iOS 26, *) {
            becomePatronButton.configuration = .prominentGlass()
        }

        if #available(iOS 27.0, visionOS 27, *) {
            scrollView.topEdgeEffect.style = .photos
        }
#endif
        becomePatronButton.configuration?.attributedTitle = .init(%"patreon.action.patron", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline)]))
//        becomePatronButton.configuration?.title = %"patreon.action.patron"
//        becomePatronButton.setTitle(%"patreon.action.patron", for: .normal)

        setupSupporters()
        binding()
        setupActions()
        viewModel.refreshSupporters()

#if os(visionOS)
        chatPin.isHidden = true
#endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSupportersHeight()
    }
}

private extension PatreonPreferencesViewController {
    func setupSupporters() {
        supportersCollection.register(SupporterCell.self, forCellWithReuseIdentifier: SupporterCell.reuseIdentifier)
        supportersCollection.register(
            UICollectionViewListCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SupportersDataSource.headerReuseIdentifier)
        supportersCollection.dataSource = supportersDataSource
        supportersCollection.allowsSelection = false
        supportersCollection.contentInsetAdjustmentBehavior = .never

        supportersCollection.collectionViewLayout = UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = true
            configuration.headerMode = .supplementary
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            section.contentInsets = .zero
            return section
        }
        supportersSizeObservation = supportersCollection.observe(\.contentSize) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateSupportersHeight()
            }
        }
    }

    func updateSupportersHeight() {
        guard !supportersSection.isHidden else { return }
        // A zero-height collection does not lay out its estimated cells. Keep a
        // nonzero viewport while the first layout resolves their actual sizes.
        let height = max(1, ceil(supportersCollection.collectionViewLayout.collectionViewContentSize.height))
        if abs(supportersHeight.constant - height) > 0.5 {
            supportersHeight.constant = height
        }
    }

    func binding() {
        disposeBag.bind {
            viewModel.supportersPublisher.uiSink { [unowned self] supporters in
                supportersDataSource.supporters = supporters
                supportersSection.isHidden = supporters.isEmpty
                supportersCollection.reloadData()
                supportersCollection.collectionViewLayout.invalidateLayout()
            }

            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).uiSink { [unowned self] _ in
                supportersCollection.reloadData()
                supportersCollection.collectionViewLayout.invalidateLayout()
            }

            viewModel.linkButtonTitle.uiSink { [unowned self] title in
//                linkPatreonButton.setTitle(title, for: .normal)
#if !os(visionOS)
                if #available(iOS 26, *) {
                    linkPatreonButton.configuration = .glass()
                }
#endif
                linkPatreonButton.configuration?.attributedTitle = .init(title, attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline)]))
//                linkPatreonButton.configuration?.title = title
            }

            Publishers.combineLatest(
                viewModel.isPatronPublisher,
                viewModel.isFullVersionPublisher)
            { $0 || $1 }.uiSink { isShown in
                UIView.animate(withDuration: 0.3) { [self] in
                    patronBox.isHidden = !isShown
                }
            }

            viewModel.isPatronPublisher.uiSink { [unowned self] isPatron in
                UIView.animate(withDuration: 0.3) { [self] in
                    becomePatronButton.isHidden = isPatron
                }
            }

            viewModel.accountState.uiSink { [unowned self] state in
                if state == .loading {
                    linkPatreonLoading.startAnimating()
                } else {
                    linkPatreonLoading.stopAnimating()
                }
            }

            viewModel.versionTextPublisher.uiSink { [unowned self] title in
                patronTitle.text = title
            }
        }
    }

    func setupActions() {
        becomePatronButton.addAction(.init { [unowned self] _ in
            let safari = BaseSafariViewController(url: URL(string: "https://patreon.com/xitrix")!)
//#if !os(visionOS)
            safari.modalPresentationStyle = .pageSheet
//#endif
            present(safari, animated: true)
        }, for: .touchUpInside)

        linkPatreonButton.addAction(.init { [unowned self] _ in
            viewModel.linkPatreon(from: linkPatreonButton)
        }, for: .touchUpInside)
    }
}

private final class SupportersDataSource: NSObject, UICollectionViewDataSource {
    static let headerReuseIdentifier = "SupportersHeader"
    var supporters: [Supporter] = []
    private let imageLoader = ImageLoader()

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        supporters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SupporterCell.reuseIdentifier, for: indexPath) as! SupporterCell
        cell.configure(with: supporters[indexPath.item], imageLoader: imageLoader)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: Self.headerReuseIdentifier,
            for: indexPath) as! UICollectionViewListCell
        var content = header.defaultContentConfiguration()
        content.text = %"patreon.supporters.title"
        header.contentConfiguration = content
        header.accessibilityTraits.insert(.header)
        return header
    }
}

private final class SupporterCell: UICollectionViewListCell {
    static let reuseIdentifier = "SupporterCell"
    private let nameLabel = UILabel()
    private let durationLabel = UILabel()
    private let avatarView = UIView()
    private let avatarImage = UIImageView()
    private let initialsLabel = UILabel()
    private var imageTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 0

        durationLabel.font = .preferredFont(forTextStyle: .footnote)
        durationLabel.adjustsFontForContentSizeCategory = true
        durationLabel.textColor = .secondaryLabel
        durationLabel.numberOfLines = 0

        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true
        initialsLabel.font = .preferredFont(forTextStyle: .subheadline)
        initialsLabel.textAlignment = .center
        initialsLabel.adjustsFontSizeToFitWidth = true
        avatarImage.contentMode = .scaleAspectFill
        for view in [initialsLabel, avatarImage] {
            view.translatesAutoresizingMaskIntoConstraints = false
            avatarView.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
                view.topAnchor.constraint(equalTo: avatarView.topAnchor),
                view.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor)
            ])
        }

        let labels = UIStackView(arrangedSubviews: [nameLabel, durationLabel])
        labels.axis = .vertical
        labels.spacing = 3
        let row = UIStackView(arrangedSubviews: [avatarView, labels])
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            separatorLayoutGuide.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        updateAvatarTint()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateAvatarTint()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        avatarImage.image = nil
    }

    func configure(with supporter: Supporter, imageLoader: ImageLoader) {
        imageTask?.cancel()
        avatarImage.image = nil
        nameLabel.text = supporter.name
        initialsLabel.text = supporter.name.split(whereSeparator: { $0.isWhitespace })
            .compactMap { $0.first(where: { $0.isLetter || $0.isNumber }) }
            .prefix(2).map(String.init).joined().localizedUppercase
        let duration = supporter.supportDuration()
        durationLabel.text = duration.map { String(format: %"patreon.supporters.duration", $0) }
        durationLabel.isHidden = duration == nil
        accessibilityLabel = [supporter.name, durationLabel.text].compactMap { $0 }.joined(separator: ", ")

        guard let url = supporter.avatarURL else { return }
        imageTask = Task { @MainActor [weak self] in
            let image = await imageLoader.loadImage(from: url)
            guard !Task.isCancelled else { return }
            self?.avatarImage.image = image
        }
    }

    private func updateAvatarTint() {
        avatarView.backgroundColor = tintColor.withAlphaComponent(0.1)
        initialsLabel.textColor = tintColor
    }

    required init?(coder: NSCoder) {
        fatalError("SupporterCell is registered programmatically")
    }
}
