//
//  Torrent.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class TorrentSdk {
    /**
    Initialise Torrent SDK with singleton engine.
    - Parameter downloadFolder: The default folder to store downloaded files.
    - Parameter configFolder: The default folder to store system files.
    */
    public static func initEngine(downloadFolder: String, configFolder: String) {
        let appName = "\(Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String) \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)"
        init_engine(appName, downloadFolder, configFolder)
    }
    
    /**
    Get base information of all downloading torrents.
    - Returns: An Array of `TorrentModel`.
    */
    public static func getTorrents() -> [TorrentModel] {
        let resRaw = get_torrent_info()
        let torrents = Array(UnsafeBufferPointer(start: resRaw.torrents, count: Int(resRaw.count)))
        let res = torrents.map { TorrentModel($0) }
        free_result(resRaw)
        return res
    }
    
    /**
    Adds Torrent to downloading stack.
    - Parameter torrentPath: absolute path to .torrent file.
    - Returns: Hash of torrent file `torrentPath`, nil if failed.
    */
    public static func addTorrent(torrentPath: String) -> String? {
        let rawRes = add_torrent(torrentPath)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        return res
    }
    
    /**
    Adds Torrent to downloading stack.
    - Parameter torrentPath: absolute path to .torrent file.
    - Parameter states: array of priorities for each file in torrent.
    */
    public static func addTorrent(torrentPath: String, states: [FileModel.TorrentDownloadPriority]) {
        var st = states.map { Int32($0.rawValue) }
        
        st.withUnsafeMutableBufferPointer { buffer in
            add_torrent_with_states(torrentPath, buffer.baseAddress)
        }
    }
    
    /**
    Adds Torrent with magnet link to downloading stack.
    - Parameter magnetUrl: magnet url.
    - Returns: Hash of torrent file `magnetUrl`, nil if failed.
    */
    @discardableResult
    public static func addMagnet(magnetUrl: String) -> String? {
        let rawRes = add_magnet(magnetUrl)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        return res
    }
    
    /**
    Remove torrent from Engine.
    - Parameter hash: hash of removeble torrent.
    - Parameter withFiles: should it  remove downloaded files?
    */
    public static func removeTorrent(hash: String, withFiles: Bool) {
        remove_torrent(hash, withFiles ? 1 : 0)
    }
    
    /**
    Save torrent added by magnet link as file.
    - Parameter hash: hash of saving torrent.
    */
    public static func saveMagnetToFile(hash: String) {
        save_magnet_to_file(hash)
    }
    
    /**
    Get hash from torrent tile.
    - Parameter torrentPath: torrent's file absolute path.
    - Returns: Hash of torrent file `torrentPath`, nil if failed.
    */
    public static func getTorrentFileHash(torrentPath: String) -> String? {
        let rawRes = get_torrent_file_hash(torrentPath)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        return res
    }
    
    /**
    Get hash from magnet link.
    - Parameter magnetUrl: torrent's magnet url.
    - Returns: Hash of `magnetUrl`, nil if failed.
    */
    public static func getMagnetHash(magnetUrl: String) -> String? {
        let rawRes = get_magnet_hash(magnetUrl)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        if res == "-1" { return nil }
        if res == "0000000000000000000000000000000000000000" { return nil }
        return res
    }
    
    /**
    Get magnet link torrent in downloading queue.
    - Parameter hash: torrent's hash.
    - Returns: Magnet link for `hash`, nil if failed.
    */
    public static func getTorrentMagnetLink(hash: String) -> String? {
        let rawRes = get_torrent_magnet_link(hash)!
        let res = String(validatingUTF8: rawRes)
        free(rawRes)
        return res
    }
    
    /**
    Get array of files from torrent file.
    - Parameter path: torrent's file absolute path.
    - Returns: Tuple with `title` - name of torrent and `files` - an array of files for it, nil if failed.
    */
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
    
    /**
    Get array of files from torrent in downloading queue.
    - Parameter hash: torrent's hash.
    - Returns: An array of files, nil if failed.
    */
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
    
    /**
    Set priority for files of torrent in downloading queue.
    - Parameter hash: torrent's hash.
    - Parameter states: arrray of priorities for each file in torrent.
    */
    public static func setTorrentFilesPriority(hash: String, states: [FileModel.TorrentDownloadPriority]) {
        if states.allSatisfy({$0 == .dontDownload}) { TorrentSdk.stopTorrent(hash: hash) }
        
        var st = states.map { Int32($0.rawValue) }
        
        st.withUnsafeMutableBufferPointer { buffer in
            set_torrent_files_priority(hash, buffer.baseAddress)
        }
    }
    
    // DO NOT USE IT!!!
//    public static func setTorrentFilePriority(hash: String, fileNum: Int, state: Int) {
//        set_torrent_file_priority(hash, Int32(fileNum), Int32(state))
//    }
    
    /**
    Call this when app resurns from suspending mode.
    */
    public static func resumeToApp() {
        resume_to_app()
    }
    
    /**
    Call this when app enters in suspending mode.
    */
    public static func saveFastResume() {
        save_fast_resume()
    }
    
    /**
    Stop downloading of torrent in queue.
    - Parameter hash: torrent's hash.
    */
    public static func stopTorrent(hash: String) {
        stop_torrent(hash)
    }
    
    /**
    Start downloading of torrent in queue.
    - Parameter hash: torrent's hash.
    */
    public static func startTorrent(hash: String) {
        start_torrent(hash)
    }
    
    /**
    Force rehash torrent in queue.
    - Parameter hash: torrent's hash.
    */
    public static func rehashTorrent(hash: String) {
        TorrentSdk.stopTorrent(hash: hash)
        rehash_torrent(hash)
    }
    
    /**
    Force update trackers of torrent in queue.
    - Parameter hash: torrent's hash.
    */
    public static func scrapeTracker(hash: String) {
        scrape_tracker(hash)
    }
    
    /**
    Get trackers of torrent in queue.
    - Parameter hash: torrent's hash.
    - Returns: An array of trackers.
    */
    public static func getTrackersByHash(hash: String) -> [TrackerModel] {
        let rawRes = get_trackers_by_hash(hash)
        let res = Array(UnsafeBufferPointer(start: rawRes.trackers, count: Int(rawRes.size))).map { TrackerModel($0) }
        free_trackers(rawRes)
        return res
    }
    
    /**
    Add tracker to torrent in queue.
    - Parameter hash: torrent's hash.
    - Parameter trackerUrl: tracker's url.
    - Returns: Is success.
    */
    public static func addTrackerToTorrent(hash: String, trackerUrl: String) -> Bool {
        Int(add_tracker_to_torrent(hash, trackerUrl)) == 0
    }
    
    /**
    Remove array of trackers from torrent in queue.
    - Parameter hash: torrent's hash.
    - Parameter trackerUrl: array of trackers url.
    - Returns: Is success.
    */
    public static func removeTrackersFromTorrent(hash: String, trackerUrls: [String]) -> Bool {
        Utils.withArrayOfCStrings(trackerUrls) { args in
            Int(remove_tracker_from_torrent(hash, args, Int32(trackerUrls.count))) == 0
        }
    }
    
    /**
    Set maximum speed of dowloading for Engine.
    - Parameter limitBytes: speed limit in bytes.
    */
    public static func setDownloadLimit(limitBytes: Int) {
        set_download_limit(Int32(limitBytes))
    }
    
    /**
    Set maximum speed of uploadeing for Engine.
    - Parameter limitBytes: speed limit in bytes.
    */
    public static func setUploadLimits(limitBytes: Int) {
        set_upload_limit(Int32(limitBytes))
    }
    
    /**
    Set sequential mode for torrent in downloading queue.
    - Parameter hash: torrent's hash.
    - Parameter sequential: enable sequential mode.
    */
    public static func setTorrentFilesSequential(hash: String, sequential: Bool) {
        set_torrent_files_sequental(hash, sequential ? 1 : 0)
    }
    
    /**
    Get sequential mode of torrent in downloading queue.
    - Parameter hash: torrent's hash.
    - Returns: Is sequential mode enabled.
    */
    public static func getTorrentFilesSequential(hash: String) -> Bool {
        get_torrent_files_sequental(hash) == 1
    }
    
    /**
    Set allocation mode for Engine.
    - Parameter allocate: enable allocation mode.
    */
    public static func setStoragePreallocation(allocate: Bool) {
        set_storage_preallocation(allocate ? 1 : 0)
    }
    
    /**
    Call alerts processing loop method for Engine which run updates of Engine states.
    */
    public static func popAlerts() {
        pop_alerts()
    }
    
    /**
    Get allocation mode for Engine.
    - Returns: Is allocation mode enabled.
    */
    public static func getStoragePreallocation() -> Bool {
        get_storage_preallocation() == 1
    }
}
