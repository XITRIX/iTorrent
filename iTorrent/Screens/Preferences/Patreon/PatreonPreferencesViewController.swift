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
    @IBOutlet private var supportersTitle: UILabel!
    @IBOutlet private var supportersCollection: UICollectionView!
    @IBOutlet private var supportersHeight: NSLayoutConstraint!

    private let supportersDataSource = SupporterNamesDataSource()
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
        supportersTitle.text = %"patreon.supporters.title"
        supportersTitle.adjustsFontForContentSizeCategory = true
        supportersTitle.accessibilityTraits.insert(.header)
        supportersCollection.register(SupporterNameCell.self, forCellWithReuseIdentifier: SupporterNameCell.reuseIdentifier)
        supportersCollection.dataSource = supportersDataSource
        supportersCollection.allowsSelection = false
        supportersCollection.contentInsetAdjustmentBehavior = .never

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(30))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        supportersCollection.collectionViewLayout = UICollectionViewCompositionalLayout(section: section)
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
            viewModel.supporterNamesPublisher.uiSink { [unowned self] names in
                supportersDataSource.names = names
                supportersSection.isHidden = names.isEmpty
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

private final class SupporterNamesDataSource: NSObject, UICollectionViewDataSource {
    var names: [String] = []

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        names.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SupporterNameCell.reuseIdentifier, for: indexPath) as! SupporterNameCell
        cell.nameLabel.text = names[indexPath.item]
        return cell
    }
}

private final class SupporterNameCell: UICollectionViewCell {
    static let reuseIdentifier = "SupporterNameCell"
    let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .secondaryLabel
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("SupporterNameCell is registered programmatically")
    }
}
