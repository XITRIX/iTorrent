//
//  TabBarView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class TabBarView: ThemedUIView {
    @IBOutlet var collectionView: UICollectionView!
    weak var viewController: UIViewController?
    weak var delegate: TabBarViewDelegate? {
        didSet {
            collectionView.reloadData()
            collectionView.performBatchUpdates(nil) { _ in
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                self.selectItem(at: indexPath)
            }
        }
    }
    
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
        collectionView?.delegate = self
        collectionView?.dataSource = self
    }
    
    func selectItem(at indexPath: IndexPath) {
        UIView.animate(withDuration: 0.3) {
            self.delegate?.filterSelected(self.cells[indexPath.item])
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            if let cell = self.collectionView.cellForItem(at: indexPath) {
                self.lineView.frame.origin.x = cell.frame.minX
                self.lineView.frame.size.width = cell.frame.width
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        viewController?.view.layoutIfNeeded()
    }
}

extension TabBarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! TabBarCell
        cell.setModel(Localize.get(cells[indexPath.item].rawValue), indexPath == selected)
        return cell
    }
}

extension TabBarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: selected) as? TabBarCell)?.setSelected(false)
        (collectionView.cellForItem(at: indexPath) as? TabBarCell)?.setSelected(true)
        selectItem(at: indexPath)
        selected = indexPath
    }
}

protocol TabBarViewDelegate: AnyObject {
    func filterSelected(_ state: TorrentState)
}

class TabBarCell: ThemedUICollectionViewCell {
    @IBOutlet var title: UILabel!
    private var _selected = false
    
    override func themeUpdate() {
        super.themeUpdate()
        backgroundColor = .clear
        setTitleColor()
    }
    
    func setTitleColor() {
        let theme = Themes.current
        title?.textColor = _selected ? theme.mainText : theme.secondaryText
    }
    
    func setModel(_ title: String, _ selected: Bool) {
        self.title?.text = title
        self._selected = selected
        setTitleColor()
    }
    
    func setSelected(_ selected: Bool) {
        self._selected = selected
        setTitleColor()
    }
}
