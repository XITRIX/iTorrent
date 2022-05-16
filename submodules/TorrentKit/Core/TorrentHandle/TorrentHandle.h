//
//  NSObject+TorrentHandle.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "TorrentHandleState.h"
#import "TorrentTracker.h"
#import "FileEntry.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TorrentHandle.Snapshot)
@interface TorrentHandleSnapshot : NSObject

@property (readonly) BOOL isValid;
@property (readonly) NSData *infoHash;
@property (readonly) NSString* name;
@property (readonly) TorrentHandleState state;
@property (readonly, nullable) NSString *creator;
@property (readonly, nullable) NSDate *creationDate;
@property (readonly) double progress;
@property (readonly) NSUInteger numberOfPeers;
@property (readonly) NSUInteger numberOfSeeds;
@property (readonly) NSUInteger numberOfLeechers;
@property (readonly) NSUInteger numberOfTotalPeers;
@property (readonly) NSUInteger numberOfTotalSeeds;
@property (readonly) NSUInteger numberOfTotalLeechers;
@property (readonly) NSUInteger downloadRate;
@property (readonly) NSUInteger uploadRate;
@property (readonly) BOOL hasMetadata;
@property (readonly) NSUInteger total;
@property (readonly) NSUInteger totalDone;
@property (readonly) NSUInteger totalWanted;
@property (readonly) NSUInteger totalWantedDone;
@property (readonly) NSUInteger totalDownload;
@property (readonly) NSUInteger totalUpload;
@property (readonly) BOOL isPaused;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isSeed;
@property (readonly) BOOL isSequential;
@property (readonly) NSArray<NSNumber *> *pieces;
//@property (readonly) NSArray<FileEntry *> *files;
@property (readonly) NSArray<TorrentTracker *> *trackers;
@property (readonly) NSString* magnetLink;
@property (readonly, nullable) NSString* torrentFilePath;
@property (readonly) NSString* downloadPath;
@end

@interface TorrentHandle : TorrentHandleSnapshot

@property (readonly) TorrentHandleSnapshot* snapshot;

//@property (readonly) NSArray<NSNumber *> *pieces;
@property (readonly) NSArray<FileEntry *> *files;

- (void)resume;
- (void)pause;
- (void)rehash;

- (void)setSequentialDownload:(BOOL)enabled;

- (void)setFilePriority:(FilePriority)priority at:(NSInteger)fileIndex;
- (void)setFilesPriority:(FilePriority)priority at:(NSArray<NSNumber *> *)fileIndexes;
- (void)setAllFilesPriority:(FilePriority)priority;

- (void)addTracker:(NSString *)url;
- (void)removeTrackers:(NSArray<NSString *> *)urls;

- (void)updateSnapshot;

@end

NS_ASSUME_NONNULL_END
