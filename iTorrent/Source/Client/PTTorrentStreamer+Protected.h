
#import "PTTorrentStreamer.h"
#import <libtorrent/session.hpp>
#import <libtorrent/torrent_info.hpp>
#import <libtorrent/add_torrent_params.hpp>
#import <GCDWebServer/GCDWebServer.h>

/**
 Variables to be used by `PTTorrentStreamer` subclasses only.
 */
@interface PTTorrentStreamer () {
    @protected
    libtorrent::session *_session;
    PTTorrentStatus _torrentStatus;
    NSString *_fileName;
    long long _requiredSpace;
    long long _totalDownloaded;
    NSString *_savePath;
    std::vector<int> required_pieces;
    long long firstPiece;
    long long endPiece;
    std::mutex mtx;
}

@property (nonatomic, strong, nullable) dispatch_queue_t alertsQueue;
@property (nonatomic, getter=isAlertsLoopActive) BOOL alertsLoopActive;
@property (nonatomic, getter=isStreaming) BOOL streaming;
@property (nonatomic, strong, nonnull) NSMutableDictionary *requestedRangeInfo;

@property (nonatomic, copy, nullable) PTTorrentStreamerProgress progressBlock;
@property (nonatomic, copy, nullable) PTTorrentStreamerReadyToPlay readyToPlayBlock;
@property (nonatomic, copy, nullable) PTTorrentStreamerFailure failureBlock;
@property (nonatomic, strong, nonnull) GCDWebServer *mediaServer;
@property (nonatomic) libtorrent::torrent_status status;
@property (nonatomic) bool isFinished;

- (void)startStreamingFromFileOrMagnetLink:(NSString * _Nonnull)filePathOrMagnetLink
                             directoryName:(NSString * _Nullable)directoryName
                                  progress:(PTTorrentStreamerProgress _Nullable)progress
                               readyToPlay:(PTTorrentStreamerReadyToPlay _Nullable)readyToPlay
                                   failure:(PTTorrentStreamerFailure _Nullable)failure;

- (void)startWebServerAndPlay;

@end
