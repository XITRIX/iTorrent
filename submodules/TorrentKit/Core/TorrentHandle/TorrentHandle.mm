//
//  NSObject+TorrentHandle.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import "TorrentHandle_Internal.h"
#import "FileEntry_Internal.h"

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

// MARK: - Functions

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
    if (enabled) {
        _torrentHandle.set_flags(lt::torrent_flags::sequential_download);
    } else {
        _torrentHandle.unset_flags(lt::torrent_flags::sequential_download);
    }
    _torrentHandle.save_resume_data();
}

- (NSArray<FileEntry *> *)files {
    auto th = _torrentHandle;
    NSMutableArray *results = [[NSMutableArray alloc] init];
    auto ti = th.torrent_file();
    if (ti == nullptr) {
        NSLog(@"No metadata for torrent with name: %s", th.status().name.c_str());
        return nil;
    }

    std::vector<int64_t> progresses;
    th.file_progress(progresses);
    auto priorities = th.get_file_priorities();

    auto info = ti.get();
    auto stat = th.status();
    auto files = info->files();
    for (int i=0; i<files.num_files(); i++) {
        auto name = std::string(files.file_name(i));
        auto path = files.file_path(i);
        auto size = files.file_size(i);
        uint8_t priority = priorities[i];

        FileEntry *fileEntry = [[FileEntry alloc] init];
        fileEntry.name = [NSString stringWithUTF8String:name.c_str()];
        fileEntry.path = [NSString stringWithUTF8String:path.c_str()];
        fileEntry.size = size;
        fileEntry.downloaded = progresses[i];
        fileEntry.priority = (FilePriority) priority;

        const auto fileSize = files.file_size(i);// > 0 ? files.file_size(i) : 0;
        const auto fileOffset = files.file_offset(i);

        const int pieceLength = info->piece_length();
        const long long beginIdx = (fileOffset / pieceLength);
        const long long endIdx = ((fileOffset + fileSize) / pieceLength);

        fileEntry.begin_idx = beginIdx;
        fileEntry.end_idx = endIdx;
        fileEntry.num_pieces = (int)(endIdx - beginIdx);
        auto array = [[NSMutableArray<NSNumber *> alloc] init];
        for (int j = 0; j < fileEntry.num_pieces; j++) {
            [array addObject: [NSNumber numberWithBool: stat.pieces.get_bit(j + (int)beginIdx)]];
        }
        fileEntry.pieces = array;

        [results addObject:fileEntry];
    }
    return [results copy];
}

- (void)setFilePriority:(FilePriority)priority at:(NSInteger)fileIndex {
    _torrentHandle.file_priority((int)fileIndex, priority);
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
