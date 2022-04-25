//
//  NSObject+TorrentHandle.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import "TorrentHandle_Internal.h"

#import "NSData+Hex.h"

#import "libtorrent/torrent_status.hpp"
#import "libtorrent/torrent_info.hpp"

@implementation TorrentHandle : NSObject

- (instancetype)initWith:(lt::torrent_handle)torrentHandle {
    self = [self init];
    if (self) {
        _torrentHandle = torrentHandle;
    }
    return self;
}

//- (libtorrent::torrent_info *)torrentInfo {
//    auto ts = _torrentHandle.status();
//    if (ts.has_metadata) {
//        return _torrentHandle.torrent_file().get();
//    }
//    return NULL;
//}

- (NSUInteger)hash {
    return self.infoHash.hash;
}

- (NSString *)infoHash {
    auto ih = _torrentHandle.info_hash();

    std::stringstream ss;
    ss << ih;
    auto str = ss.str();

    return [[NSString alloc] initWithFormat:@"%s", str.c_str()];
}

- (NSString *)name {
    auto ts = _torrentHandle.status();
    return [[NSString alloc] initWithFormat:@"%s", ts.name.c_str()];
}

- (NSString * _Nullable)creator {
    auto ts = _torrentHandle.status();

    if (ts.has_metadata) {
        auto info = _torrentHandle.torrent_file().get();
        return [[NSString alloc] initWithFormat:@"%s", info->creator().c_str()];
    }

    return NULL;
}

- (NSDate * _Nullable)creationDate {
    auto ts = _torrentHandle.status();

    if (ts.has_metadata) {
        auto info = _torrentHandle.torrent_file().get();
        return [[NSDate alloc] initWithTimeIntervalSince1970:info->creation_date()];
    }

    return NULL;
}

- (TorrentHandleState)state {
    auto status = _torrentHandle.status();
    switch (status.state) {
        case lt::torrent_status::state_t::checking_files: return TorrentHandleStateCheckingFiles;
        case lt::torrent_status::state_t::downloading_metadata: return TorrentHandleStateDownloadingMetadata;
        case lt::torrent_status::state_t::downloading: return TorrentHandleStateDownloading;
        case lt::torrent_status::state_t::finished: return TorrentHandleStateFinished;
        case lt::torrent_status::state_t::seeding: return TorrentHandleStateSeeding;
        case lt::torrent_status::state_t::allocating: return TorrentHandleStateAllocating;
        case lt::torrent_status::state_t::checking_resume_data: return TorrentHandleStateCheckingResumeData;
    }
}

- (double)progress {
    auto status = _torrentHandle.status();
    return status.progress;
}

- (NSUInteger)numberOfPeers {
    auto status = _torrentHandle.status();
    return status.num_peers;
}

- (NSUInteger)numberOfSeeds {
    auto status = _torrentHandle.status();
    return status.num_seeds;
}

- (NSUInteger)numberOfLeechers {
    return self.numberOfPeers - self.numberOfPeers;
}

- (NSUInteger)numberOfTotalPeers {
    auto status = _torrentHandle.status();
    int peers = status.num_complete + status.num_incomplete;
    return peers > 0 ? peers : status.list_peers;
}

- (NSUInteger)numberOfTotalSeeds {
    auto status = _torrentHandle.status();
    int complete = status.num_complete;
    return complete > 0 ? complete : status.list_seeds;
}

- (NSUInteger)numberOfTotalLeechers {
    auto status = _torrentHandle.status();
    int incomplete = status.num_incomplete;
    return incomplete > 0 ? incomplete : status.list_peers - status.list_seeds;
}

- (NSUInteger)downloadRate {
    auto status = _torrentHandle.status();
    return status.download_payload_rate;
}

- (NSUInteger)uploadRate {
    auto status = _torrentHandle.status();
    return status.upload_payload_rate;
}

- (BOOL)hasMetadata {
    auto status = _torrentHandle.status();
    return status.has_metadata;
}

- (NSUInteger)total {
    auto ts = _torrentHandle.status();

    if (ts.has_metadata) {
        auto info = _torrentHandle.torrent_file().get();
        return info->total_size();
    }

    return NULL;
}

- (NSUInteger)totalDone {
    auto ts = _torrentHandle.status();
    return ts.total_done;
}

- (NSUInteger)totalWanted {
    auto ts = _torrentHandle.status();
    return ts.total_wanted;
}

- (NSUInteger)totalWantedDone {
    auto ts = _torrentHandle.status();
    return ts.total_wanted_done;
}

- (NSUInteger)totalDownload {
    auto ts = _torrentHandle.status();
    return ts.total_download;
}

- (NSUInteger)totalUpload {
    auto ts = _torrentHandle.status();
    return ts.total_upload;
}

- (BOOL)isPaused {
    auto ts = _torrentHandle.status();
    return ts.flags & lt::torrent_flags::paused;
}

- (BOOL)isFinished {
    auto ts = _torrentHandle.status();
    return ts.total_wanted == ts.total_wanted_done;
}

- (BOOL)isSeed {
    auto ts = _torrentHandle.status();
    return ts.is_seeding;
}

- (BOOL)isSequential {
    auto ts = _torrentHandle.status();
    return ts.flags & lt::torrent_flags::sequential_download;
}

- (void)resume {
    _torrentHandle.set_flags(lt::torrent_flags::auto_managed);
    _torrentHandle.resume();
}

- (void)pause {
    _torrentHandle.unset_flags(lt::torrent_flags::auto_managed);
    _torrentHandle.pause();
}

- (void)rehash {
    _torrentHandle.force_recheck();
    _torrentHandle.set_flags(lt::torrent_flags::auto_managed);
}

- (void)setSequentialDownload:(BOOL)enabled {
    auto th = _torrentHandle;
    if (enabled) {
        th.set_flags(lt::torrent_flags::sequential_download);
    } else {
        th.unset_flags(lt::torrent_flags::sequential_download);
    }
    th.save_resume_data();
}

- (void)setFilePriority:(uint8_t)priority forFile:(NSInteger)index {
    _torrentHandle.file_priority((int)index, priority);
    _torrentHandle.save_resume_data();
}

- (void)setFilesPriority:(NSArray<NSNumber *> *)priorities {
    std::vector<lt::download_priority_t> array;
    for (int i = 0; i < priorities.count; i++) {
        array.push_back([[priorities objectAtIndex:i] integerValue]);
    }
    _torrentHandle.prioritize_files(array);
    _torrentHandle.save_resume_data();
}

@end
