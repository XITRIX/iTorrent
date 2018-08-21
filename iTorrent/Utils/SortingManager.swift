//
//  SortingManager.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 17.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SortingManager {
	
	public enum SortingTypes : Int {
		case Name = 0
		case DateAdded = 1
		case DateCreated = 2
		case Size = 3
	}
	
	public static func createSortingController(buttonItem: UIBarButtonItem? = nil, applyChanges: @escaping ()->() = {}) -> ThemedUIAlertController {
		let alphabetAction = createAlertButton(NSLocalizedString("Name", comment: ""), SortingTypes.Name, applyChanges);
		let dateAddedAction = createAlertButton(NSLocalizedString("Date Added", comment: ""), SortingTypes.DateAdded, applyChanges);
		let dateCreatedAction = createAlertButton(NSLocalizedString("Date Created", comment: ""), SortingTypes.DateCreated, applyChanges);
		let sizeAction = createAlertButton(NSLocalizedString("Size", comment: ""), SortingTypes.Size, applyChanges);
		
		let sectionsAction = createSectionsAlertButton(applyChanges);
		
		let cancel = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: UIAlertActionStyle.cancel, handler: nil);
		
        var sortAlertController = ThemedUIAlertController(title: NSLocalizedString("Sort Torrents By:", comment: ""), message: nil, preferredStyle: .actionSheet)
		
		var message = NSLocalizedString("Currently sorted by ", comment: "");
		checkConditionToAddButtonToList(&sortAlertController, &message, alphabetAction, SortingTypes.Name);
		checkConditionToAddButtonToList(&sortAlertController, &message, dateAddedAction, SortingTypes.DateAdded);
		checkConditionToAddButtonToList(&sortAlertController, &message, dateCreatedAction, SortingTypes.DateCreated);
		checkConditionToAddButtonToList(&sortAlertController, &message, sizeAction, SortingTypes.Size);
		
		sortAlertController.addAction(sectionsAction);
		sortAlertController.addAction(cancel);
		
		sortAlertController.message = message;
		
		if (sortAlertController.popoverPresentationController != nil && buttonItem != nil) {
			sortAlertController.popoverPresentationController?.barButtonItem = buttonItem;
		}
		
		return sortAlertController;
	}
	
	private static func createAlertButton(_ buttonName: String, _ sortingType: SortingTypes, _ applyChanges: @escaping ()->() = {}) -> UIAlertAction {
		return UIAlertAction(title: buttonName, style: .default) { _ in
			UserDefaults.standard.set(sortingType.rawValue, forKey: "SortingType")
			applyChanges()
		}
	}
	
	private static func createSectionsAlertButton(_ applyChanges: @escaping ()->() = {}) -> UIAlertAction {
		let sections = UserDefaults.standard.bool(forKey: "SortingSections")
		let name = sections ? NSLocalizedString("Disable state sections", comment: "") : NSLocalizedString("Enable state sections", comment: "")
		return UIAlertAction(title: name, style: sections ? .destructive : .default) { _ in
			UserDefaults.standard.set(!sections, forKey: "SortingSections")
			applyChanges()
		}
	}
	
	private static func checkConditionToAddButtonToList(_ sortAlertController: inout ThemedUIAlertController, _ message: inout String, _ alertAction: UIAlertAction, _ sortingType: SortingTypes) {
		if (SortingTypes(rawValue: UserDefaults.standard.integer(forKey: "SortingType")) != sortingType) {
			sortAlertController.addAction(alertAction)
		} else {
			message.append(alertAction.title!)
		}
	}
	
	public static func sortTorrentManagers(managers: [TorrentStatus], headers: inout [String]) -> [[TorrentStatus]] {
		var res = [[TorrentStatus]]()
		var localManagers = [TorrentStatus](managers)
		headers = [String]()
		
		if (UserDefaults.standard.value(forKey: "SortingSections") == nil) {
			UserDefaults.standard.set(true, forKey: "SortingSections");
		}
		
		if (UserDefaults.standard.bool(forKey: "SortingSections")) {
			
			var allocatingManagers = [TorrentStatus]();
			var checkingFastresumeManagers = [TorrentStatus]();
			var downloadingManagers = [TorrentStatus]();
			var finishedManagers = [TorrentStatus]();
			var hashingManagers = [TorrentStatus]();
			var metadataManagers = [TorrentStatus]();
			var pausedManagers = [TorrentStatus]();
			var queuedManagers = [TorrentStatus]();
			var seedingManagers = [TorrentStatus]();
			
			for manager in localManagers {
				switch (manager.displayState) {
				case Utils.torrentStates.Allocating.rawValue:
					allocatingManagers.append(manager);
					break;
				case Utils.torrentStates.CheckingFastresume.rawValue:
					checkingFastresumeManagers.append(manager);
					break;
				case Utils.torrentStates.Downloading.rawValue:
					downloadingManagers.append(manager);
					break;
				case Utils.torrentStates.Finished.rawValue:
					finishedManagers.append(manager);
					break;
				case Utils.torrentStates.Hashing.rawValue:
					hashingManagers.append(manager);
					break;
				case Utils.torrentStates.Metadata.rawValue:
					metadataManagers.append(manager);
					break;
				case Utils.torrentStates.Paused.rawValue:
					pausedManagers.append(manager);
					break;
				case Utils.torrentStates.Queued.rawValue:
					queuedManagers.append(manager);
					break;
				case Utils.torrentStates.Seeding.rawValue:
					seedingManagers.append(manager);
					break;
				default:
					break;
				}
			}
            
            let sortingOrder = UserDefaults.standard.value(forKey: UserDefaultsKeys.sectionsSortingOrder) as! [Int]
            for id in sortingOrder {
                let state = Utils.torrentStates.init(id: id)!
                switch (state) {
                case .Allocating:
                    addManager(&res, &allocatingManagers, &headers, Utils.torrentStates.Allocating.rawValue)
                    break
                case .CheckingFastresume:
                    addManager(&res, &checkingFastresumeManagers, &headers, Utils.torrentStates.CheckingFastresume.rawValue)
                case .Downloading:
                    addManager(&res, &downloadingManagers, &headers, Utils.torrentStates.Downloading.rawValue)
                case .Finished:
                    addManager(&res, &finishedManagers, &headers, Utils.torrentStates.Finished.rawValue)
                case .Hashing:
                    addManager(&res, &hashingManagers, &headers, Utils.torrentStates.Hashing.rawValue)
                    break
                case .Metadata:
                    addManager(&res, &metadataManagers, &headers, Utils.torrentStates.Metadata.rawValue)
                    break
                case .Paused:
                    addManager(&res, &pausedManagers, &headers, Utils.torrentStates.Paused.rawValue)
                    break
                case .Queued:
                    addManager(&res, &queuedManagers, &headers, Utils.torrentStates.Queued.rawValue)
                    break
                case .Seeding:
                    addManager(&res, &seedingManagers, &headers, Utils.torrentStates.Seeding.rawValue)
                    break
                }
            }
		} else {
			headers.append("");
			simpleSort(&localManagers);
			res.append(localManagers);
		}
		
		return res;
	}
	
	private static func addManager(_ res: inout [[TorrentStatus]], _ list: inout [TorrentStatus], _ headers: inout [String], _ header: String ) {
		if (list.count > 0) {
			simpleSort(&list);
			headers.append(header);
			res.append(list);
		}
	}
	
	private static func simpleSort(_ list: inout [TorrentStatus]) {
		switch (SortingTypes(rawValue: UserDefaults.standard.integer(forKey: "SortingType"))!) {
			case SortingTypes.Name:
				list.sort { (t1, t2) -> Bool in
					t1.title < t2.title
				}
				break
			case SortingTypes.DateAdded:
				list.sort { (t1, t2) -> Bool in
					t1.addedDate! > t2.addedDate!
				}
				break
			case SortingTypes.DateCreated:
				list.sort { (t1, t2) -> Bool in
					t1.creationDate! > t2.creationDate!
				}
				break
			case SortingTypes.Size:
				list.sort { (t1, t2) -> Bool in
					t1.totalWanted > t2.totalWanted
				}
				break
		}
	}
	
}
