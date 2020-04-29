//
//  Torrent.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class TorrentSdk {
    public static func initEngine(downloadFolder: String, configFolder: String) {
        let appName = "\(Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String) \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)"
        init_engine(appName, downloadFolder, configFolder)
    }
    
    public static func getTorrents() -> [TorrentModel] {
        let resRaw = get_torrent_info()
        let torrents = Array(UnsafeBufferPointer(start: resRaw.torrents, count: Int(resRaw.count)))
        let res = torrents.map { TorrentModel($0) }
        free_result(resRaw)
        return res
    }
    
    public static func addTorrent(torrentPath: String) -> String? {
        let rawRes = add_torrent(torrentPath)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        return res
    }
    
    public static func addTorrent(torrentPath: String, states: [FileModel.TorrentDownloadPriority]) {
        let st = states.map { Int32($0.rawValue) }
        add_torrent_with_states(torrentPath, UnsafeMutablePointer(mutating: st))
    }
    
    public static func addMagnet(magnetUrl: String) -> String? {
        let rawRes = add_magnet(magnetUrl)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        return res
    }
    
    public static func removeTorrent(hash: String, withFiles: Bool) {
        remove_torrent(hash, withFiles ? 1 : 0)
    }
    
    public static func saveMagnetToFile(hash: String) {
        save_magnet_to_file(hash)
    }
    
    public static func getTorrentFileHash(torrentPath: String) -> String? {
        let rawRes = get_torrent_file_hash(torrentPath)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        return res
    }
    
    public static func getMagnetHash(magnetUrl: String) -> String? {
        let rawRes = get_magnet_hash(magnetUrl)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        return res
    }
    
    public static func getTorrentMagnetLink(hash: String) -> String? {
        let rawRes = get_torrent_magnet_link(hash)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        return res
    }
    
    public static func getFilesOfTorrentByPath(path: String) -> (title: String, files: [FileModel])? {
        let rawRes = get_files_of_torrent_by_path(path)
        if rawRes.error == 1 {
            free_files(rawRes)
            return nil
        }
        let title = String(validatingUTF8: rawRes.title) ?? "ERROR"
        let res = (title, Array(UnsafeBufferPointer(start: rawRes.files, count: Int(rawRes.size))).map { FileModel(file: $0, isPreview: true) })
        free_files(rawRes)
        return res
    }
    
    public static func getFilesOfTorrentByHash(hash: String) -> [FileModel]? {
        let rawRes = get_files_of_torrent_by_hash(hash)
        if rawRes.error == 1 {
            free_files(rawRes)
            return nil
        }
        let res = Array(UnsafeBufferPointer(start: rawRes.files, count: Int(rawRes.size))).map { FileModel(file: $0) }
        free_files(rawRes)
        return res
    }
    
    public static func setTorrentFilesPriority(hash: String, states: [FileModel.TorrentDownloadPriority]) {
        if states.allSatisfy({$0 == .dontDownload}) { TorrentSdk.stopTorrent(hash: hash) }
        
        let st = states.map { Int32($0.rawValue) }
        set_torrent_files_priority(hash, UnsafeMutablePointer(mutating: st))
    }
    
    // DO NOT USE IT!!!
//    public static func setTorrentFilePriority(hash: String, fileNum: Int, state: Int) {
//        set_torrent_file_priority(hash, Int32(fileNum), Int32(state))
//    }
    
    public static func resumeToApp() {
        resume_to_app()
    }
    
    public static func saveFastResume() {
        save_fast_resume()
    }
    
    public static func stopTorrent(hash: String) {
        stop_torrent(hash)
    }
    
    public static func startTorrent(hash: String) {
        start_torrent(hash)
    }
    
    public static func rehashTorrent(hash: String) {
        rehash_torrent(hash)
    }
    
    public static func scrapeTracker(hash: String) {
        scrape_tracker(hash)
    }
    
    public static func getTrackersByHash(hash: String) -> [TrackerModel] {
        let rawRes = get_trackers_by_hash(hash)
        let res = Array(UnsafeBufferPointer(start: rawRes.trackers, count: Int(rawRes.size))).map { TrackerModel($0) }
        free_trackers(rawRes)
        return res
    }
    
    public static func addTrackerToTorrent(hash: String, trackerUrl: String) -> Int {
        Int(add_tracker_to_torrent(hash, trackerUrl))
    }
    
    public static func removeTrackersFromTorrent(hash: String, trackerUrls: [String]) -> Int {
        Utils.withArrayOfCStrings(trackerUrls) { args in
            Int(remove_tracker_from_torrent(hash, args, Int32(trackerUrls.count)))
        }
    }
    
    public static func setDownloadLimit(limitBytes: Int) {
        set_download_limit(Int32(limitBytes))
    }
    
    public static func setUploadLimits(limitBytes: Int) {
        set_upload_limit(Int32(limitBytes))
    }
    
    public static func setTorrentFilesSequential(hash: String, sequential: Bool) {
        set_torrent_files_sequental(hash, sequential ? 1 : 0)
    }
    
    public static func getTorrentFilesSequential(hash: String) -> Bool {
        get_torrent_files_sequental(hash) == 1
    }
    
    public static func setStoragePreallocation(allocate: Bool) {
        set_storage_preallocation(allocate ? 1 : 0)
    }
    
    public static func getStoragePreallocation() -> Bool {
        get_storage_preallocation() == 1
    }
}
