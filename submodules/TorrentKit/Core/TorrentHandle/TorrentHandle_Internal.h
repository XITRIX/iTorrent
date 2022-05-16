//
//  TorrentHandle_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>
#import "TorrentHandle.h"

#import "libtorrent/torrent_handle.hpp"
#import "Session.h"

NS_ASSUME_NONNULL_BEGIN

@interface TorrentHandleSnapshot ()

@property (readwrite) BOOL isValid;
@property (readwrite) NSData *infoHash;
@property (readwrite) NSString* name;
@property (readwrite) TorrentHandleState state;
@property (readwrite, nullable) NSString *creator;
@property (readwrite, nullable) NSDate *creationDate;
@property (readwrite) double progress;
@property (readwrite) NSUInteger numberOfPeers;
@property (readwrite) NSUInteger numberOfSeeds;
@property (readwrite) NSUInteger numberOfLeechers;
@property (readwrite) NSUInteger numberOfTotalPeers;
@property (readwrite) NSUInteger numberOfTotalSeeds;
@property (readwrite) NSUInteger numberOfTotalLeechers;
@property (readwrite) NSUInteger downloadRate;
@property (readwrite) NSUInteger uploadRate;
@property (readwrite) BOOL hasMetadata;
@property (readwrite) NSUInteger total;
@property (readwrite) NSUInteger totalDone;
@property (readwrite) NSUInteger totalWanted;
@property (readwrite) NSUInteger totalWantedDone;
@property (readwrite) NSUInteger totalDownload;
@property (readwrite) NSUInteger totalUpload;
@property (readwrite) BOOL isPaused;
@property (readwrite) BOOL isFinished;
@property (readwrite) BOOL isSeed;
@property (readwrite) BOOL isSequential;
@property (readwrite) NSArray<NSNumber *> *pieces;
//@property (readwrite) NSArray<FileEntry *> *files;
@property (readwrite) NSArray<TorrentTracker *> *trackers;
@property (readwrite) NSString* magnetLink;
@property (readwrite, nullable) NSString* torrentFilePath;
@property (readwrite) NSString* downloadPath;
@end

@interface TorrentHandle ()
@property lt::torrent_handle torrentHandle;
@property NSString *torrentPath;
@property NSString *sessionDownloadPath;

@property (readwrite) TorrentHandleSnapshot* snapshot;

- (instancetype)initWith:(lt::torrent_handle)torrentHandle inSession:(Session *)session;
@end

NS_ASSUME_NONNULL_END
