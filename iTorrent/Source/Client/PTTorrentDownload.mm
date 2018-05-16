

#import "PTTorrentDownload.h"
#import "PTSize.h"
#import "PTTorrentStreamer+Protected.h"
#import "PTTorrentDownloadManagerListener.h"
#import <MediaPlayer/MPMediaItem.h>
#import <UIKit/UIApplication.h>

NSString * const PTTorrentItemPropertyDownloadStatus = @"downloadStatus";
NSString * const MPMediaItemPropertyPathOrLink = @"filePathOrLink";
NSString * const PTTorrentItemPropertyTorrentProgress = @"progress";

using namespace libtorrent;

@implementation PTTorrentDownload {
    PTTorrentDownloadStatus _downloadStatus;
}

- (PTTorrentDownloadStatus)downloadStatus {
    return _downloadStatus;
}

+ (NSString *)downloadDirectory {
    NSURL *URL;
    
    #if TARGET_OS_IOS
    URL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    #elif TARGET_OS_TV
    URL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    #endif
    
    NSString *downloadDirectory =  [[URL path] stringByAppendingPathComponent:@"Downloads"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadDirectory]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) return nil;
    }
    
    return downloadDirectory;
}

- (instancetype)initFromPlist:(NSString *)pathToPlist {
    NSDictionary<NSString *, id> *dictionary = [NSDictionary dictionaryWithContentsOfFile:pathToPlist];
    
    PTTorrentDownloadStatus downloadStatus = (PTTorrentDownloadStatus)[[dictionary objectForKey:PTTorrentItemPropertyDownloadStatus] integerValue];
    
    float progress = [[dictionary objectForKey:PTTorrentItemPropertyTorrentProgress] floatValue];
    
    NSString *savePath = [pathToPlist stringByDeletingLastPathComponent];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:savePath];
    NSString *fileName;
    
    while (fileName = [enumerator nextObject]) {
        NSString *pathExtension = [fileName pathExtension];
        if ([pathExtension isEqualToString: @"mp4"] || [pathExtension isEqualToString: @"mkv"]) break;
    }
    
    long long requiredSpace = [[[[NSFileManager defaultManager] attributesOfItemAtPath:[savePath stringByAppendingPathComponent:fileName] error:nil] objectForKey:NSFileSize] longLongValue];
    
    if (dictionary != nil && savePath != nil && fileName != nil) {
        @try {
            self = [self initWithMediaMetadata:dictionary downloadStatus:downloadStatus];
            _savePath = savePath;
            _fileName = fileName;
            _requiredSpace = requiredSpace;
            _totalDownloaded = requiredSpace;
            self.isFinished = downloadStatus == PTTorrentDownloadStatusFinished;
            self.torrentStatus = {0, progress, 0, 0, 0, 0};
            return self;
        } @catch (NSException *exception) {
            return nil;
        }
    }
    return nil;
}

- (instancetype)initWithMediaMetadata:(NSDictionary<NSString *, id> *)mediaMetadata downloadStatus:(PTTorrentDownloadStatus)downloadStatus {
    NSAssert([mediaMetadata objectForKey: MPMediaItemPropertyPersistentID] != nil, @"MPMediaItemPropertyPersistentID property must be set.");
    
    for (id value in [mediaMetadata allValues]) {
        NSArray *validClasses = @[[NSData class], [NSDate class], [NSNumber class], [NSString class], [NSArray class], [NSDictionary class]];
        
        BOOL isSubclass = NO;
        
        for (id validClass in validClasses) {
            if ([[value class] isSubclassOfClass:validClass]) {
                isSubclass = YES;
                break;
            }
        }
        
        NSAssert(isSubclass, @"All mediaMetadata values must be instances of NSData, NSDate, NSNumber, NSString, NSArray, or NSDictionary for a valid property list file to be created. %@ is not.", value);
    }
    
    self = [super init];
    if (self) {
        _downloadStatus = downloadStatus;
        _mediaMetadata = mediaMetadata;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[PTTorrentDownload class]]) {
        return [((PTTorrentDownload *)object).mediaMetadata[MPMediaItemPropertyPersistentID] isEqualToString:self.mediaMetadata[MPMediaItemPropertyPersistentID]];
    }
    return NO;
}

- (NSUInteger)hash {
    return [_mediaMetadata[MPMediaItemPropertyPersistentID] hash];
}


- (void)startDownloadingFromFileOrMagnetLink:(NSString *)filePathOrMagnetLink {
    __weak __typeof__(self) weakSelf = self;
    
    NSMutableDictionary *copy = _mediaMetadata.mutableCopy;
    copy[MPMediaItemPropertyPathOrLink] = filePathOrMagnetLink;
    _mediaMetadata = copy;
    
    [super startStreamingFromFileOrMagnetLink:filePathOrMagnetLink directoryName:_mediaMetadata[MPMediaItemPropertyPersistentID] progress:^(PTTorrentStatus status) {
        if (weakSelf.downloadStatus == PTTorrentDownloadStatusPaused) return;
        PTTorrentDownloadStatus downloadStatus = status.totalProgress < 1 ? PTTorrentDownloadStatusDownloading : PTTorrentDownloadStatusFinished;
        
        [weakSelf setDownloadStatus:downloadStatus];
        [weakSelf setTorrentStatus:status];
        
        if (downloadStatus == PTTorrentDownloadStatusFinished) {
            [self cancelStreamingAndDeleteData:NO];
        }
    } readyToPlay:nil failure:^(NSError * _Nonnull error) {
        id<PTTorrentDownloadManagerListener> delegate = weakSelf.delegate;
        
        [weakSelf setDownloadStatus:PTTorrentDownloadStatusFailed];
        
        if (delegate && [delegate respondsToSelector:@selector(downloadDidFail:withError:)]) {
            [delegate downloadDidFail:weakSelf withError:error];
        }
    }];
}


- (void)setTorrentStatus:(PTTorrentStatus)torrentStatus {
    _torrentStatus = torrentStatus;
    
    if (_delegate && [_delegate respondsToSelector:@selector(torrentStatusDidChange:forDownload:)]) {
        [_delegate torrentStatusDidChange:torrentStatus forDownload:self];
    }
}

- (void)setDownloadStatus:(PTTorrentDownloadStatus)downloadStatus {
    if (downloadStatus == _downloadStatus) return;
    
    _downloadStatus = downloadStatus;
    
    if (_delegate && [_delegate respondsToSelector:@selector(downloadStatusDidChange:forDownload:)]) {
        [_delegate downloadStatusDidChange:downloadStatus forDownload:self];
    }
}

- (void)stop {
    [super cancelStreamingAndDeleteData:YES];
    [self setDownloadStatus:PTTorrentDownloadStatusFailed];
}

- (void)pause {
    if (_downloadStatus != PTTorrentDownloadStatusDownloading) return;
    
    _session->pause();
    [self setDownloadStatus:PTTorrentDownloadStatusPaused];
    
    #if TARGET_OS_IOS
      dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
      });
    #endif
}

- (void)resume {
    if (_downloadStatus != PTTorrentDownloadStatusPaused) return;
    
    if (_session->get_torrents().size() == 0) // Torrent was in the middle of downloading and app was exited. Download has been loaded from disk and is now being resumed. Fetch torrent metadata instead of just resuming.
    {
        [self startDownloadingFromFileOrMagnetLink:_mediaMetadata[MPMediaItemPropertyPathOrLink]];
        return [self setDownloadStatus:PTTorrentDownloadStatusProcessing];
    }
    
    if (_session->is_paused()) {
       _session->resume();
    }
    [self setDownloadStatus:PTTorrentDownloadStatusDownloading];
    
    #if TARGET_OS_IOS
      dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
      });
    #endif
}

- (BOOL)delete {
    NSAssert(_downloadStatus != PTTorrentDownloadStatusPaused && _downloadStatus != PTTorrentDownloadStatusDownloading, @"This method should not be used to stop downloads, only to delete a pre-existing download.");
    return [[NSFileManager defaultManager] removeItemAtPath:_savePath error:nil];
}

- (BOOL)save {
    NSString *filePath = [_savePath stringByAppendingPathComponent:@"Metadata.plist"];
    NSMutableDictionary *copy = _mediaMetadata.mutableCopy;
    [copy setObject:@(_downloadStatus) forKey:PTTorrentItemPropertyDownloadStatus];
    [copy setObject:@(_torrentStatus.totalProgress) forKey:PTTorrentItemPropertyTorrentProgress];
    return [copy writeToFile:filePath atomically:YES];
}

- (void)playWithHandler:(PTTorrentStreamerReadyToPlay)handler {
    if (_downloadStatus != PTTorrentDownloadStatusFinished) return;
    self.readyToPlayBlock = handler;
    [self startWebServerAndPlay];
}

- (void)cancelStreamingAndDeleteData:(BOOL)deleteData {
    
    std::vector<torrent_handle> ths = _session->get_torrents();
    for(std::vector<torrent_handle>::size_type i = 0; i != ths.size(); i++) {
        ths[i].pause();
        if (!deleteData && ths[i].need_save_resume_data())ths[i].save_resume_data();
        ths[i].flush_cache();
        _session->pause();
        if (deleteData)_session->remove_torrent(ths[i]);
    }
    
    required_pieces.clear();
    required_pieces.shrink_to_fit();
    [self.requestedRangeInfo removeAllObjects];
    
    self.progressBlock = nil;
    self.readyToPlayBlock = nil;
    self.failureBlock = nil;
    if (self.mediaServer.isRunning) [self.mediaServer stop];
    [self.mediaServer removeAllHandlers];
    
    if (deleteData) {
        self.alertsQueue = nil;
        self.alertsLoopActive = NO;
    }
    
    firstPiece = -1;
    endPiece = 0;
    
    self.streaming = NO;
    
    #if TARGET_OS_IOS
      dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
      });
    #endif
}

@end
