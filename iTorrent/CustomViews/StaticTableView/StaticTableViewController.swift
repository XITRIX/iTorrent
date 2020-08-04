//
//  StaticTableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class StaticTableViewController: ThemedUIViewController {
    var useInsertStyle: Bool? {
        nil
    }
    
    let disposalBag = DisposalBag()
    override var toolBarIsHidden: Bool? {
        true
    }
    
    var tableAnimation: UITableView.RowAnimation {
        .top
    }
    
    var tableView: StaticTableView!
    var data: [Section] = [] {
        didSet {
            tableView?.data = data
        }
    }
    
    var initStyle: UITableView.Style = .grouped
    
    init() {
        super.init(nibName: nil, bundle: Bundle.main)
    }
    
    init(style: UITableView.Style) {
        super.init(nibName: nil, bundle: Bundle.main)
        initStyle = style
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setup(style: UITableView.Style = .grouped) {}
    
    override func loadView() {
        super.loadView()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        tableView = StaticTableView(frame: view.frame, style: initStyle)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.colorType = .secondary
        view.addSubview(tableView)
        tableView.data = data
        tableView.tableAnimation = tableAnimation
        tableView.useInsertStyle = useInsertStyle
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSections()
        updateData()
        
        KeyboardHelper.shared.visibleHeight.bind { [weak self] height in
            guard let self = self else { return }
            
            let offset = self.tableView.contentOffset
            UIView.animate(withDuration: 0.3) {
                self.tableView.contentInset.bottom = height
                self.tableView.scrollIndicatorInsets.bottom = height
                self.tableView.contentOffset = offset
            }
        }.dispose(with: disposalBag)
    }
    
    func initSections() {}
    
    func updateData(animated: Bool = true) {
        tableView?.updateData(animated: animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if useInsertStyle != nil,
            previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            tableView.useInsertStyle = useInsertStyle
            tableView.reloadData()
        }
    }
}
