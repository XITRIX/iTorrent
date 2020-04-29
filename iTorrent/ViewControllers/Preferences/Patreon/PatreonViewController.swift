//
//  PatreonViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import SafariServices
import UIKit

class PatreonViewController: ThemedUIViewController {
    @IBOutlet var icon: UIImageView!
    @IBOutlet var chatPin: UIImageView!
    @IBOutlet var patronButton: UIButton!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var patronInfo: UIView!
    
    @IBOutlet var backplates: [UIView]!
    
    @IBOutlet var nameLabel: ThemedUILabel!
    @IBOutlet var creatorLabel: ThemedUILabel!
    @IBOutlet var welcomeLabel: ThemedUILabel!
    @IBOutlet var patronLabel: ThemedUILabel!
    @IBOutlet var adsfreeLabel: ThemedUILabel!
    
    @IBOutlet var thanksLabel: ThemedUILabel!
    @IBOutlet var patronsSection: UIStackView!
    @IBOutlet var patronsLoading: UIActivityIndicatorView!
    @IBOutlet var patronsCollectionView: UICollectionView!
    @IBOutlet var patronsCollectionViewHeight: NSLayoutConstraint!
    
    var patrons: [String]?
    
    func Localization() {
        nameLabel.text = Localize.get("Settings.Patreon.Name")
        creatorLabel.text = Localize.get("Settings.Patreon.Creator")
        welcomeLabel.text = Localize.get("Settings.Patreon.Welcome")
        adsfreeLabel.text = Localize.get("Settings.Patreon.Reward")
        patronButton.setTitle(Localize.get("Settings.Patreon.PatronButton"), for: .normal)
        thanksLabel.text = Localize.get("Settings.Patreon.Thanks")
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        
        view.backgroundColor = theme.backgroundMain
        chatPin.tintColor = theme.backgroundSecondary
        backplates.forEach { $0.backgroundColor = theme.backgroundSecondary }
        patronsLoading.style = theme.loadingIndicatorStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Localization()
        updateButtonsState(animated: false)
        
        let alignedFlowLayout = patronsCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout
        alignedFlowLayout?.horizontalAlignment = .left
        alignedFlowLayout?.verticalAlignment = .center
        alignedFlowLayout?.minimumLineSpacing = 0
        
        patronsCollectionView.dataSource = self
        patronsCollectionView.delegate = self
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(iconTapRecognizer))
        tapRecognizer.numberOfTapsRequired = 7
        icon.addGestureRecognizer(tapRecognizer)
        
        updateData()
    }
    
    @objc func iconTapRecognizer() {
        if let account = UserPreferences.patreonAccount {
            UIPasteboard.general.string = account.identifier
            Dialog.withTimer(self, title: nil, message: Localize.get("Settings.Patreon.CopiedID"))
        }
    }
    
    func updateData() {
        PatreonAPI.shared.fetchCredentials { _ in
            PatreonAPI.shared.fetchPatrons { [weak self] result in
                do {
                    guard let self = self else { return }
                    self.patrons = try result.get()
                        .filter { $0.benefits.contains(where: { $0.type == .credits }) }
                        .sorted { $0.name < $1.name }
                        .map { $0.name }
                    
                    // self.patrons = ["F", "Aawdsfaw", "Afqwfwsfwq", "Anfxgtehydnfgdbf", "Aawedfghtuyiuk", "Atuyrtydhrtgbrv", "Aadsbtnuyiu", "Ayuftjyhgfe", "Awefwfwefwefcht", "wdfwefwdfA", "Afwefwdef", "Awefsdfwe"]
                    var normalCount = self.patrons!.count
                    if normalCount & 1 != 0 { normalCount += 1 }
                    let height = normalCount * 14
                    DispatchQueue.main.async {
                        self.patronsCollectionView.reloadData()
                        UIView.animate(withDuration: 0.3) {
                            self.patronsLoading.isHiddenInStackView = true
                            self.patronsCollectionViewHeight.constant = CGFloat(height)
                            self.view.layoutIfNeeded()
                        }
                    }
                } catch {
                    print("Failed to fetch patrons:", error)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PatreonAPI.shared.fetchAccount { [weak self] result in
            do {
                _ = try result.get()
                
                DispatchQueue.main.async {
                    self?.updateButtonsState()
                }
            } catch {}
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        patronsCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    func updateButtonsState(animated: Bool = true) {
        if let account = UserPreferences.patreonAccount {
            if account.isPatron || account.fullVersion {
                setViewHidden(patronInfo, hidden: false, animated: animated)

                if account.fullVersion {
                    patronLabel.text = Localize.get("Settings.Patreon.Full")
                } else if account.isPatron {
                    patronLabel.text = Localize.get("Settings.Patreon.Patron")
                }
            } else {
                setViewHidden(patronInfo, hidden: true, animated: animated)
            }
            
            if account.isPatron {
                setViewHidden(patronButton, hidden: true, animated: animated)
            } else {
                setViewHidden(patronButton, hidden: false, animated: animated)
            }
            connectButton.setTitle(Localize.get("Settings.Patreon.UnlinkButton") + " " + account.name, for: .normal)
        } else {
            setViewHidden(patronInfo, hidden: true, animated: animated)
            setViewHidden(patronButton, hidden: false, animated: animated)
            connectButton.setTitle(Localize.get("Settings.Patreon.LinkButton"), for: .normal)
        }
    }
    
    func setViewHidden(_ view: UIView, hidden: Bool, animated: Bool = true) {
        if !animated {
            view.isHiddenInStackView = hidden
            view.alpha = hidden ? 0 : 1
        } else {
            UIView.animate(withDuration: 0.3) {
                view.isHiddenInStackView = hidden
                view.alpha = hidden ? 0 : 1
            }
        }
    }
    
    @IBAction func patronButtonAction(_ sender: UIButton) {
        let safari = SFSafariViewController(url: URL(string: "https://patreon.com/xitrix")!)
        safari.modalPresentationStyle = .pageSheet
        if #available(iOS 10.0, *) {
            safari.preferredControlTintColor = Themes.current.tintColor
        }
        if #available(iOS 13.0, *) {
            safari.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: Themes.current.overrideUserInterfaceStyle!)!
        }
        Utils.rootViewController.present(safari, animated: true)
    }
    
    @IBAction func connectButtonAction(_ sender: UIButton) {
        if UserPreferences.patreonAccount != nil {
            let alert = ThemedUIAlertController(title: Localize.get("Settings.Patreon.UnlinkButton.Text"), message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.frame
            
            let unlink = UIAlertAction(title: Localize.get("Settings.Patreon.UnlinkButton.Action"), style: .destructive) { _ in
                PatreonAPI.shared.signOut { [weak self] result in
                    do {
                        try result.get()
                        
                        DispatchQueue.main.async {
                            self?.updateButtonsState()
                        }
                    } catch {}
                }
            }
            let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)
            
            alert.addAction(unlink)
            alert.addAction(cancel)
            
            present(alert, animated: true)
            
        } else {
            PatreonAPI.shared.authenticate { [weak self] result in
                do {
                    _ = try result.get()
                    
                    DispatchQueue.main.async {
                        self?.updateButtonsState()
                    }
                } catch {}
            }
        }
    }
}

extension PatreonViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        patrons?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PatronCell", for: indexPath) as! PatronNameCell
        cell.title.text = patrons?[indexPath.item]
        return cell
    }
}

extension PatreonViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
        let size: CGFloat = (collectionView.frame.size.width - space) / 2.0
        return CGSize(width: size, height: 28)
    }
}
