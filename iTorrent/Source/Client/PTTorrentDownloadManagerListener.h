
#import <Foundation/Foundation.h>
#import "PTTorrentStatus.h"
#import "PTTorrentDownloadStatus.h"

@class PTTorrentDownload;

NS_ASSUME_NONNULL_BEGIN

/**
 A listener protocol for receiving status updates for downloads.
 */
@protocol PTTorrentDownloadManagerListener <NSObject>

@optional

/**
 Called when the torrent status of a download changes.
 
 @param torrentStatus   The status of the torrent (speed, progress, seeds, peers etc.).
 @param download        The download that's status has changed.
 */
- (void)torrentStatusDidChange:(PTTorrentStatus)torrentStatus forDownload:(PTTorrentDownload *)download;

/**
 Called when the download status of a download changes.
 
 @param downloadStatus  The download status of the torrent (downloading, paused, stopped, failed etc.).
 @param download        The download that's status has changed.
 */
- (void)downloadStatusDidChange:(PTTorrentDownloadStatus)downloadStatus forDownload:(PTTorrentDownload *)download;

/**
 Called when a download fails.
 
 @param download    The download that has failed.
 @param error       The underlying error.
 */
- (void)downloadDidFail:(PTTorrentDownload *)download withError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
