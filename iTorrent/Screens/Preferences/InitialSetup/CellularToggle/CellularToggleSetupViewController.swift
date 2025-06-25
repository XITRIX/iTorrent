//
//  CellularToggleSetupViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit

class CellularToggleSetupViewController<VM: CellularToggleSetupViewModel>: BaseViewController<VM> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var allowCellularButton: UIButton!
    @IBOutlet private var disableCellularButton: UIButton!
    @IBOutlet private var buttonsContainerView: UIView!
    @IBOutlet private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        binding()

        isModalInPresentation = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentInset.bottom = buttonsContainerView.frame.height
    }
}

private extension CellularToggleSetupViewController {
    func setup() {
        titleLabel.text = %"initialSetup.cellular.title"
        messageLabel.text = %"initialSetup.cellular.message"

        allowCellularButton.configuration?.attributedTitle = .init(%"initialSetup.cellular.button.allow", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline)]))

        if #available(iOS 26, visionOS 26, *) {
            disableCellularButton.configuration = .prominentGlass()
            disableCellularButton.configuration?.buttonSize = .large
            disableCellularButton.configuration?.cornerStyle = .large
        }
        disableCellularButton.configuration?.attributedTitle = .init(%"initialSetup.cellular.button.dismiss", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline)]))

        disableCellularButton.addAction(.init { [unowned self] _ in
            viewModel.disableCellularAction()
        }, for: .touchUpInside)

        allowCellularButton.addAction(.init { [unowned self] _ in
            viewModel.allowCellularAction()
        }, for: .touchUpInside)
    }

    func binding() {}
}
