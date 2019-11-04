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

    public enum SortingTypes: Int {
        case name = 0
        case dateAdded = 1
        case dateCreated = 2
        case size = 3
    }

    public static func createSortingController(buttonItem: UIBarButtonItem? = nil, applyChanges: @escaping () -> Void = {
    }) -> ThemedUIAlertController {
        let alphabetAction = createAlertButton(NSLocalizedString("Name", comment: ""), SortingTypes.name, applyChanges)
        let dateAddedAction = createAlertButton(NSLocalizedString("Date Added", comment: ""), SortingTypes.dateAdded, applyChanges)
        let dateCreatedAction = createAlertButton(NSLocalizedString("Date Created", comment: ""), SortingTypes.dateCreated, applyChanges)
        let sizeAction = createAlertButton(NSLocalizedString("Size", comment: ""), SortingTypes.size, applyChanges)

        let sectionsAction = createSectionsAlertButton(applyChanges)

        let cancel = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: UIAlertAction.Style.cancel, handler: nil)

        var sortAlertController = ThemedUIAlertController(title: NSLocalizedString("Sort Torrents By:", comment: ""), message: nil, preferredStyle: .actionSheet)

        var message = NSLocalizedString("Currently sorted by ", comment: "")
        checkConditionToAddButtonToList(&sortAlertController, &message, alphabetAction, SortingTypes.name)
        checkConditionToAddButtonToList(&sortAlertController, &message, dateAddedAction, SortingTypes.dateAdded)
        checkConditionToAddButtonToList(&sortAlertController, &message, dateCreatedAction, SortingTypes.dateCreated)
        checkConditionToAddButtonToList(&sortAlertController, &message, sizeAction, SortingTypes.size)

        sortAlertController.addAction(sectionsAction)
        sortAlertController.addAction(cancel)

        sortAlertController.message = message

        if sortAlertController.popoverPresentationController != nil, buttonItem != nil {
            sortAlertController.popoverPresentationController?.barButtonItem = buttonItem
        }

        return sortAlertController
    }

    private static func createAlertButton(_ buttonName: String, _ sortingType: SortingTypes, _ applyChanges: @escaping () -> Void = {
    }) -> UIAlertAction {
        UIAlertAction(title: buttonName, style: .default) { _ in
            UserPreferences.sortingType.value = sortingType.rawValue
            applyChanges()
        }
    }

    private static func createSectionsAlertButton(_ applyChanges: @escaping () -> Void = {
    }) -> UIAlertAction {
        let sections = UserPreferences.sortingSections.value
        let name = sections ? NSLocalizedString("Disable state sections", comment: "") : NSLocalizedString("Enable state sections", comment: "")
        return UIAlertAction(title: name, style: sections ? .destructive : .default) { _ in
            UserPreferences.sortingSections.value = !sections
            applyChanges()
        }
    }

    private static func checkConditionToAddButtonToList(_ sortAlertController: inout ThemedUIAlertController, _ message: inout String, _ alertAction: UIAlertAction, _ sortingType: SortingTypes) {
        if SortingTypes(rawValue: UserPreferences.sortingType.value) != sortingType {
            sortAlertController.addAction(alertAction)
        } else {
            message.append(alertAction.title!)
        }
    }

    public static func sortTorrentManagers(managers: [TorrentStatus], headers: inout [String]) -> [[TorrentStatus]] {
        var res = [[TorrentStatus]]()
        var localManagers = [TorrentStatus](managers)
        headers = [String]()

        if UserPreferences.sortingSections.value {

            var collection = [String: [TorrentStatus]]()
            collection[Utils.TorrentStates.allocating.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.checkingFastresume.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.downloading.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.finished.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.hashing.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.metadata.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.paused.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.queued.rawValue] = [TorrentStatus]()
            collection[Utils.TorrentStates.seeding.rawValue] = [TorrentStatus]()

            for manager in localManagers {
                collection[manager.displayState]?.append(manager)
            }

            let sortingOrder = UserPreferences.sectionsSortingOrder.value
            for id in sortingOrder {
                let state = Utils.TorrentStates.init(id: id)!

                if var list = collection[state.rawValue] {
                    addManager(&res, &list, &headers, state.rawValue)
                }
            }
        } else {
            headers.append("")
            simpleSort(&localManagers)
            res.append(localManagers)
        }

        return res
    }

//    public static func sortTorrentManagers2(managers: [TorrentStatus], headers: inout [String]) -> [[TorrentStatus]] {
//        var res = [[TorrentStatus]]()
//        var localManagers = [TorrentStatus](managers)
//        headers = [String]()
//
//        if (UserPreferences.sortingSections.value) {
//
//            var allocatingManagers = [TorrentStatus]()
//            var checkingFastresumeManagers = [TorrentStatus]()
//            var downloadingManagers = [TorrentStatus]()
//            var finishedManagers = [TorrentStatus]()
//            var hashingManagers = [TorrentStatus]()
//            var metadataManagers = [TorrentStatus]()
//            var pausedManagers = [TorrentStatus]()
//            var queuedManagers = [TorrentStatus]()
//            var seedingManagers = [TorrentStatus]()
//
//            for manager in localManagers {
//                switch (manager.displayState) {
//                case Utils.torrentStates.Allocating.rawValue:
//                    allocatingManagers.append(manager)
//                case Utils.torrentStates.CheckingFastresume.rawValue:
//                    checkingFastresumeManagers.append(manager)
//                case Utils.torrentStates.Downloading.rawValue:
//                    downloadingManagers.append(manager)
//                case Utils.torrentStates.Finished.rawValue:
//                    finishedManagers.append(manager)
//                case Utils.torrentStates.Hashing.rawValue:
//                    hashingManagers.append(manager)
//                case Utils.torrentStates.Metadata.rawValue:
//                    metadataManagers.append(manager)
//                case Utils.torrentStates.Paused.rawValue:
//                    pausedManagers.append(manager)
//                case Utils.torrentStates.Queued.rawValue:
//                    queuedManagers.append(manager)
//                case Utils.torrentStates.Seeding.rawValue:
//                    seedingManagers.append(manager)
//                default:
//                    break
//                }
//            }
//
//            let sortingOrder = UserPreferences.sectionsSortingOrder.value
//            for id in sortingOrder {
//                let state = Utils.torrentStates.init(id: id)!
//                switch (state) {
//                case .Allocating:
//                    addManager(&res, &allocatingManagers, &headers, Utils.torrentStates.Allocating.rawValue)
//                case .CheckingFastresume:
//                    addManager(&res, &checkingFastresumeManagers, &headers, Utils.torrentStates.CheckingFastresume.rawValue)
//                case .Downloading:
//                    addManager(&res, &downloadingManagers, &headers, Utils.torrentStates.Downloading.rawValue)
//                case .Finished:
//                    addManager(&res, &finishedManagers, &headers, Utils.torrentStates.Finished.rawValue)
//                case .Hashing:
//                    addManager(&res, &hashingManagers, &headers, Utils.torrentStates.Hashing.rawValue)
//                case .Metadata:
//                    addManager(&res, &metadataManagers, &headers, Utils.torrentStates.Metadata.rawValue)
//                case .Paused:
//                    addManager(&res, &pausedManagers, &headers, Utils.torrentStates.Paused.rawValue)
//                case .Queued:
//                    addManager(&res, &queuedManagers, &headers, Utils.torrentStates.Queued.rawValue)
//                case .Seeding:
//                    addManager(&res, &seedingManagers, &headers, Utils.torrentStates.Seeding.rawValue)
//                }
//            }
//        } else {
//            headers.append("")
//            simpleSort(&localManagers)
//            res.append(localManagers)
//        }
//
//        return res
//    }

    private static func addManager(_ res: inout [[TorrentStatus]], _ list: inout [TorrentStatus], _ headers: inout [String], _ header: String) {
        if list.count > 0 {
            simpleSort(&list)
            headers.append(header)
            res.append(list)
        }
    }

    private static func simpleSort(_ list: inout [TorrentStatus]) {
        switch (SortingTypes(rawValue: UserPreferences.sortingType.value)!) {
        case SortingTypes.name:
            list.sort { (t1, t2) -> Bool in
                t1.title < t2.title
            }
        case SortingTypes.dateAdded:
            list.sort { (t1, t2) -> Bool in
                t1.addedDate! > t2.addedDate!
            }
        case SortingTypes.dateCreated:
            list.sort { (t1, t2) -> Bool in
                t1.creationDate! > t2.creationDate!
            }
        case SortingTypes.size:
            list.sort { (t1, t2) -> Bool in
                t1.totalWanted > t2.totalWanted
            }
        }
    }

}
