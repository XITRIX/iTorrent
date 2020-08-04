//
//  TabBarView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 28.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class TabBarView: UITableViewHeaderFooterView, Themed {
    static let id = "TabBarView"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    
    @IBOutlet var fxView: UIVisualEffectView!
    @IBOutlet var collectionView: UICollectionView!
    weak var delegate: TabBarViewDelegate?
    
    var selected = IndexPath(item: 0, section: 0)
    let cells: [TorrentState] = [.null,
                                 .finished,
                                 .downloading,
                                 .seeding,
                                 .paused,
                                 .metadata]
    
    lazy var lineView: UIView = {
        let view = TintView(frame: CGRect(x: 0, y: frame.height - 8, width: 10, height: 3))
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1.5
        collectionView.addSubview(view)
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
        
        collectionView.register(TabBarItemCell.nib, forCellWithReuseIdentifier: TabBarItemCell.id)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    @objc func themeUpdate() {
        fxView.effect = UIBlurEffect(style: Themes.current.blurEffect)
    }
    
    private func selectItem(at indexPath: IndexPath, animated: Bool = true) {
        func action() {
            self.delegate?.filterSelected(self.cells[indexPath.item])
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            print(indexPath)
            if let cell = self.collectionView.cellForItem(at: indexPath) {
                self.lineView.frame.origin.x = cell.frame.minX
                self.lineView.frame.size.width = cell.frame.width
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                action()
            }
        } else { action() }
    }
    
    func setModel(_ delegate: TabBarViewDelegate, selected: TorrentState) {
        self.delegate = delegate
        self.selected = IndexPath(item: cells.firstIndex(of: selected) ?? 0, section: 0)
        
        collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.collectionView.selectItem(at: self.selected, animated: false, scrollPosition: .centeredHorizontally)
            self.selectItem(at: self.selected, animated: false)
        }
    }
}

extension TabBarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabBarItemCell.id, for: indexPath) as! TabBarItemCell
        cell.setModel(Localize.get(cells[indexPath.item].rawValue), indexPath == selected)
        return cell
    }
}

extension TabBarView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: selected) as? TabBarItemCell)?.setSelected(false)
        (collectionView.cellForItem(at: indexPath) as? TabBarItemCell)?.setSelected(true)
        selectItem(at: indexPath)
        selected = indexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 0, height: 44)
    }
}

protocol TabBarViewDelegate: AnyObject {
    func filterSelected(_ state: TorrentState)
}
