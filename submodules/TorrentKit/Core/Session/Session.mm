//
//  TorrentSession.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "Session_Internal.h"
#import "Downloadable.h"
#import "TorrentFile_Internal.h"
#import "TorrentHandle_Internal.h"
#import "NSData+Hex.h"
#import "NSData+Sha1Hash.h"

//libtorrent
#import "libtorrent/session.hpp"
#import "libtorrent/alert.hpp"
#import "libtorrent/alert_types.hpp"

#import "libtorrent/write_resume_data.hpp"
#import "libtorrent/torrent_handle.hpp"
#import "libtorrent/torrent_info.hpp"
#import "libtorrent/create_torrent.hpp"
#import "libtorrent/magnet_uri.hpp"

#import "libtorrent/bencode.hpp"
#import "libtorrent/bdecode.hpp"

static NSErrorDomain ErrorDomain = @"ru.xitrix.TorrentKit.Session.error";
static NSString *EventsQueueIdentifier = @"ru.xitrix.TorrentKit.Session.events.queue";
static NSString *FileEntriesQueueIdentifier = @"ru.xitrix.TorrentKit.Session.files.queue";

@implementation Session : NSObject

// MARK: - Init
- (instancetype)initWith:(NSString *)downloadPath torrentsPath:(NSString *)torrentsPath fastResumePath:(NSString *)fastResumePath {
    self = [super init];
    if (self) {
        _downloadPath = downloadPath;
        _torrentsPath = torrentsPath;
        _fastResumePath = fastResumePath;

        NSError * error;
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadPath withIntermediateDirectories:YES attributes:nil error:&error];
        [[NSFileManager defaultManager] createDirectoryAtPath:torrentsPath withIntermediateDirectories:YES attributes:nil error:&error];
        [[NSFileManager defaultManager] createDirectoryAtPath:fastResumePath withIntermediateDirectories:YES attributes:nil error:&error];

        lt::settings_pack p;
        p.set_int(lt::settings_pack::alert_mask, lt::alert_category::all);
        _session = new lt::session(p);

        _filesQueue = dispatch_queue_create([FileEntriesQueueIdentifier UTF8String], DISPATCH_QUEUE_SERIAL);
        _delegates = [NSHashTable weakObjectsHashTable];

        // restore session
        [self restoreSession];

        // start alerts loop
        _eventsThread = [[NSThread alloc] initWithTarget:self selector:@selector(alertsLoop) object:nil];
        [_eventsThread setName: EventsQueueIdentifier];
        [_eventsThread setQualityOfService:NSQualityOfServiceDefault];
        [_eventsThread start];
    }
    return self;
}

- (void)dealloc {
    delete _session;
}

// MARK: - Path
- (NSString *)fastResumePathForInfoHash:(NSData *)infoHash {
    return [[_fastResumePath stringByAppendingPathComponent:infoHash.hexString] stringByAppendingPathExtension:@"fastresume"];
}

- (NSString *)magnetURIsFilePath {
    return [_fastResumePath stringByAppendingPathExtension:@"magnet_links"];
}

// MARK: - Public
- (void)restoreSession {
    NSError *error;
    // load .torrents files
    NSArray *torrentsDirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_torrentsPath error:&error];
    NSLog(@"%@", _torrentsPath);
    if (error) { NSLog(@"%@", error); }

    torrentsDirFiles = [torrentsDirFiles filteredArrayUsingPredicate:
                        [NSPredicate predicateWithFormat:@"self ENDSWITH %@", @".torrent"]];
    for (NSString *fileName in torrentsDirFiles) {
        NSString *filePath = [_torrentsPath stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        TorrentFile *torrent = [[TorrentFile alloc] initWithFileAtURL:fileURL];
        [self addTorrent:torrent];
    }
}
- (void)addDelegate:(id<SessionDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<SessionDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

- (BOOL)addTorrent:(id<Downloadable>)torrent {
    lt::add_torrent_params params;

    try {
        [torrent configureAddTorrentParams:&params forSession:self];
    } catch (...) {
        NSError *error = [self errorWithCode:ErrorCodeBadFile message:@"Failed to add torrent"];
        NSLog(@"%@", error);
//        [self notifyDelegatesAboutError:error];
        return NO;
    }

    params.save_path = [_downloadPath UTF8String];
    auto th = _session->add_torrent(params);


    [torrent configureAfterAdded: [[TorrentHandle alloc] initWith:th]];

    return YES;
}

// MARK: - Private
- (NSError *)errorWithCode:(ErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:ErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}


// MARK: - Alerts Loop

#define ALERTS_LOOP_WAIT_MILLIS 500

- (void)alertsLoop {
    auto max_wait = lt::milliseconds(ALERTS_LOOP_WAIT_MILLIS);
    while (YES) {
        auto alert_ptr = _session->wait_for_alert(max_wait);
        std::vector<lt::alert *> alerts_queue;
        if (alert_ptr != nullptr) {
            _session->pop_alerts(&alerts_queue);
        } else {
            continue;
        }

        for (auto it = alerts_queue.begin(); it != alerts_queue.end(); ++it) {
            auto alert = (*it);
//            NSLog(@"type:%d msg:%s", alert->type(), alert->message().c_str());
            switch (alert->type()) {
                case lt::metadata_received_alert::alert_type: {
                } break;

                case lt::metadata_failed_alert::alert_type: {
                    [self metadataReceivedAlert:(lt::torrent_alert *)alert];
                } break;

                case lt::block_finished_alert::alert_type: {
                } break;

                case lt::add_torrent_alert::alert_type: {
                    [self torrentAddedAlert:(lt::torrent_alert *)alert];
                } break;

                case lt::torrent_removed_alert::alert_type: {
                    [self torrentRemovedAlert:(lt::torrent_alert *)alert];
                } break;

                case lt::torrent_finished_alert::alert_type: {
                    [self torrentStateChanged:(lt::torrent_alert *)alert];
                } break;

                case lt::torrent_paused_alert::alert_type: {
                    [self torrentStateChanged:(lt::torrent_alert *)alert];
                } break;

                case lt::torrent_resumed_alert::alert_type: {
                    [self torrentStateChanged:(lt::torrent_alert *)alert];
                } break;

                case lt::torrent_error_alert::alert_type: {
                } break;

                case lt::save_resume_data_alert::alert_type: {
                    [self torrentSaveFastResume:(lt::save_resume_data_alert *)alert];
                } break;

                default: break;
            }

            if (dynamic_cast<lt::torrent_alert *>(alert) != nullptr) {
                auto th = ((lt::torrent_alert *)alert)->handle;
                if (!th.is_valid()) { break; }
                [self notifyDelegatesWithUpdate:th];
            }
        }

        alerts_queue.clear();
    }
}

- (void)notifyDelegatesWithAdd:(lt::torrent_handle)th {
    TorrentHandle *torrent = [[TorrentHandle alloc] initWith:th];
    for (id<SessionDelegate>delegate in self.delegates) {
        [delegate torrentManager:self didAddTorrent:torrent];
    }
}

- (void)notifyDelegatesWithRemove:(lt::torrent_handle)th {
    NSData *hashData = [[NSData alloc] initWith:th.info_hash()];
    for (id<SessionDelegate>delegate in self.delegates) {
        [delegate torrentManager:self didRemoveTorrentWithHash:hashData];
    }
}

- (void)notifyDelegatesWithUpdate:(lt::torrent_handle)th {
    TorrentHandle *torrent = [[TorrentHandle alloc] initWith:th];
    for (id<SessionDelegate>delegate in self.delegates) {
        [delegate torrentManager:self didReceiveUpdateForTorrent:torrent];
    }
}

- (void)metadataReceivedAlert:(lt::torrent_alert *)alert {
    auto th = alert->handle;
}

- (void)torrentAddedAlert:(lt::torrent_alert *)alert {
    auto th = alert->handle;
    [self notifyDelegatesWithAdd:th];
    if (!th.is_valid()) {
        NSLog(@"%s: torrent_handle is invalid!", __FUNCTION__);
        return;
    }

    bool has_metadata = th.status().has_metadata;
    auto torrent_info = th.torrent_file();
    auto margnet_uri = lt::make_magnet_uri(th);
    dispatch_async(self.filesQueue, ^{
        if (has_metadata) {
            [self saveTorrentFileWithInfo:torrent_info];
        } else {
            [self saveMagnetURIWithContent:margnet_uri];
        }
    });
}

- (void)torrentRemovedAlert:(lt::torrent_alert *)alert {
    auto th = alert->handle;
    [self notifyDelegatesWithRemove:th];
    if (!th.is_valid()) {
        NSLog(@"%s: torrent_handle is invalid!", __FUNCTION__);
        return;
    }

    auto torrent_info = th.torrent_file();
    auto info_hash = th.info_hash();
    dispatch_async(self.filesQueue, ^{
        [self removeTorrentFileWithInfo:torrent_info];
        [self removeMagnetURIWithHash:info_hash];
    });
}

- (void)torrentStateChanged:(lt::torrent_alert *)alert {
    auto th = alert->handle;
    th.save_resume_data();
}

- (void)torrentSaveFastResume:(lt::save_resume_data_alert *)alert {
    std::vector<char> ret;
    lt::entry rd = lt::write_resume_data(alert->params);
    bencode(std::back_inserter(ret), rd);

    lt::torrent_handle h = alert->handle;
    auto ih = h.info_hash();

    auto data = [NSData dataWithBytes:ih.data() length:ih.size()];
    auto nspath = [self fastResumePathForInfoHash: data];
    std::string path = std::string([nspath UTF8String]);

    std::fstream f(path, std::ios_base::trunc | std::ios_base::out | std::ios_base::binary);
    f.write(ret.data(), ret.size());
}

// MARK: - Torrent saving
- (void)saveTorrentFileWithInfo:(std::shared_ptr<const lt::torrent_info>)ti {
    if (ti == nullptr) { return; }

    lt::create_torrent new_torrent(*ti);
    std::vector<char> out_file;
    lt::bencode(std::back_inserter(out_file), new_torrent.generate());

    NSString *fileName = [NSString stringWithFormat:@"%s.torrent", (*ti).name().c_str()];
    NSString *filePath = [_torrentsPath stringByAppendingPathComponent:fileName];
    NSData *data = [NSData dataWithBytes:out_file.data() length:out_file.size()];
    BOOL success = [data writeToFile:filePath atomically:YES];
    if (!success) { NSLog(@"Can't save .torrent file"); }
}

- (void)saveMagnetURIWithContent:(std::string)uri {
    if (uri.length() < 1) { return; }

    NSString *magnetURI = [NSString stringWithUTF8String:uri.c_str()];
    [self appendMagnetURIToFileStore:magnetURI];
}

- (void)appendMagnetURIToFileStore:(NSString *)magnetURI {
    // read from existing file
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:[self magnetURIsFilePath]
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (error) { NSLog(@"%@", error); }

    NSMutableArray *magnetURIs = [[fileContent componentsSeparatedByString:@"\n"] mutableCopy];
    if (magnetURIs == nil) {
        magnetURIs = [[NSMutableArray alloc] init];
    }
    // remove all existing copies
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF CONTAINS[cd] %@)", magnetURI];
    [magnetURIs filterUsingPredicate:predicate];
    // add new uri
    [magnetURIs addObject:magnetURI];

    // save to file
    fileContent = [magnetURIs componentsJoinedByString:@"\n"];
    [fileContent writeToFile:[self magnetURIsFilePath]
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
    if (error) { NSLog(@"%@", error); }
}

// MARK: - Torrent deletion
- (void)removeTorrentFileWithInfo:(std::shared_ptr<const lt::torrent_info>)ti {
    if (ti == nullptr) { return; }

    NSString *fileName = [NSString stringWithFormat:@"%s.torrent", (*ti).name().c_str()];
    NSString *filePath = [_torrentsPath stringByAppendingPathComponent:fileName];

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) { NSLog(@"success: %d, %@", success, error); }
}

- (void)removeMagnetURIWithHash:(lt::sha1_hash)info_hash {
    NSData *hashData = [[NSData alloc] initWith:info_hash];
    [self removeFromFileStoreMagnetURIWithHash:hashData.hexString];
}

- (void)removeFromFileStoreMagnetURIWithHash:(NSString *)hashString {
    // read from existing file
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:[self magnetURIsFilePath]
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (error) { NSLog(@"%@", error); }

    NSMutableArray *magnetURIs = [[fileContent componentsSeparatedByString:@"\n"] mutableCopy];
    // remove all existing copies
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF CONTAINS[cd] %@)", hashString];
    [magnetURIs filterUsingPredicate:predicate];

    // save to file
    fileContent = [magnetURIs componentsJoinedByString:@"\n"];
    [fileContent writeToFile:[self magnetURIsFilePath]
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
    if (error) { NSLog(@"%@", error); }
}

@end
