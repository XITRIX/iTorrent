//
//  TorrentSession.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "Downloadable.h"
#import "TorrentFile.h"
#import "FileEntry.h"
#import "SessionSettings.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ErrorCode) {
    ErrorCodeBadFile,
    ErrorCodeUndefined
} NS_SWIFT_NAME(ErrorCode);

@class Session, TorrentHandle;
@protocol SessionDelegate
- (void)torrentManager:(Session *)manager didAddTorrent:(TorrentHandle *)torrent;
- (void)torrentManager:(Session *)manager didRemoveTorrentWithHash:(NSData *)hashData;
- (void)torrentManager:(Session *)manager didReceiveUpdateForTorrent:(TorrentHandle *)torrent;
- (void)torrentManager:(Session *)manager didErrorOccur:(NSError *)error;
@end

@interface Session : NSObject

@property (readwrite, strong, nonatomic) NSString *downloadPath;
@property (readwrite, strong, nonatomic) NSString *torrentsPath;
@property (readwrite, strong, nonatomic) NSString *fastResumePath;

@property (readwrite, nonatomic) SessionSettings *settings;

@property (readonly) NSArray<TorrentHandle *> *torrents;

- (instancetype)initWith:(NSString *)downloadPath torrentsPath:(NSString *)torrentsPath fastResumePath:(NSString *)fastResumePath settings:(SessionSettings *)settings;

- (NSString *)fastResumePathForInfoHash:(NSData *)infoHash;

- (void)addDelegate:(id<SessionDelegate>)delegate;
- (void)removeDelegate:(id<SessionDelegate>)delegate;

- (void)restoreSession;

- (BOOL)addTorrent:(id<Downloadable>)torrent;
- (void)removeTorrent:(TorrentHandle *)torrent deleteFiles:(BOOL)deleteFiles;

@end

NS_ASSUME_NONNULL_END
