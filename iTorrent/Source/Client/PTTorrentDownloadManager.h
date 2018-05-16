

#import <Foundation/Foundation.h>
#import "PTTorrentStreamer.h"

@class PTTorrentDownload;
@protocol PTTorrentDownloadManagerListener;

NS_ASSUME_NONNULL_BEGIN

/**
 A class that manages torrent downloads.
 */
@interface PTTorrentDownloadManager : NSObject

/**
 Signs the specified object up for `PTTorrentDownloadManagerListener` delegate requests.
 
 @param listener    The object to be signed up for delegate requests.
 */
- (void)addListener:(id<PTTorrentDownloadManagerListener>)listener;

/**
 Resigns the specified object from `PTTorrentDownloadManagerListener` delegate requests.
 
 @param listener    The object to be resigned from delegate requests.
 */
- (void)removeListener:(id<PTTorrentDownloadManagerListener>)listener;

/**
 Shared singleton instance.
 */
+ (instancetype)sharedManager;

/**
 Begins streaming of a torrent. To recieve status updates about the download, sign up for delegate requests using the  `addListener:` method.
 
 @param filePathOrMagnetLink    The direct link of a locally stored `.torrent` file or a `magnet:?` link.
 @param mediaMetadata           Metadata for the current download. Use `MPMediaItem` keys.
 
 @return    The download instance.
 
 @warning   Only one property in the `mediaMetadata` dictionary must be set: `MPMediaItemPropertyPersistentID`. If this is not set, an exception will be raised. Also, if every `mediaMetadata` value is not an instance of `NSData`, `NSDate`, `NSNumber`, `NSString`, `NSArray`, or `NSDictionary`, an exception will be raised.
 */
- (PTTorrentDownload *)startDownloadingFromFileOrMagnetLink:(NSString *)filePathOrMagnetLink mediaMetadata:(NSDictionary<NSString *, id> *)mediaMetadata;

/**
 Stops the specified download, deletes all download progress (if any) and removes the download object from the `activeDownloads` array.
 
 @param download    The download to stop.
 */
- (void)stopDownload:(PTTorrentDownload *)download;

/**
 Pauses the specified download.
 
 @param download    The download to pause.
 */
- (void)pauseDownload:(PTTorrentDownload *)download;

/**
 Resumes the specified download.
 
 @param download    The download to resume.
 */
- (void)resumeDownload:(PTTorrentDownload *)download;

/**
 Deletes the current download.
 
 @param download    The download to delete.
 
 @return    Boolean indicating the success of the operation.
 
 @warning   This method should not be used to stop a download. If the download is running and this method is called, an exception will be raised.
 */
- (BOOL)deleteDownload:(PTTorrentDownload *)download;

/**
 Saves metadata about the current download so it can be resumed at a later date
 
 @param download    The download to save.
 
 @return    Boolean indicating the success of the operation.
 
 @warning   This method should be run on a background thread as it could take a while to save depending on how much metdata there is.
 */
- (BOOL)saveDownload:(PTTorrentDownload *)download;

/**
 Starts a webserver to play local content.
 
 @param download    The download to play.
 @param handler Block called when the torrent has finished processing and is ready to begin being played.
 */
- (void)playDownload:(PTTorrentDownload *)download withHandler:(PTTorrentStreamerReadyToPlay)handler;

/**
 An array of all the torrents currently downloading.
 */
@property (strong, nonatomic, readonly) NSArray<PTTorrentDownload *> *activeDownloads;

/**
 An array of all the torrents that have finished downloading.
 */
@property (strong, nonatomic, readonly) NSArray<PTTorrentDownload *> *completedDownloads;

@end

NS_ASSUME_NONNULL_END


