

#import <Foundation/Foundation.h>
#import "PTTorrentStreamer.h"
#import "PTTorrentDownloadStatus.h"

@protocol PTTorrentDownloadManagerListener;

NS_ASSUME_NONNULL_BEGIN

/**
 A class that downloads magnet links or `.torrent` files.
 */
@interface PTTorrentDownload : PTTorrentStreamer

/**
 The status of the current download.
 */
@property (nonatomic, readonly) PTTorrentDownloadStatus downloadStatus;

/**
 The delegate `PTTorrentDownloadManagerListener` requests.
 */
@property (weak, nonatomic, nullable) id<PTTorrentDownloadManagerListener> delegate;

/**
 Metadata for the current download.
 */
@property (strong, nonatomic) NSDictionary<NSString *, id> *mediaMetadata;

/**
 Stops the current download and deletes all download progress (if any). Once you call stop you can not resume the download - `startDownloadingFromFileOrMagnetLink:` will have to be called again.
 */
- (void)stop;

/**
 Resumes the current download (if possible).
 */
- (void)resume;

/**
 Pauses the current download.
 */
- (void)pause;

/**
 Deletes the current download.
 
 @return    Boolean indicating the success of the operation.
 
 @warning   This method should not be used to stop a download. If the download is running and this method is called, an exception will be raised.
 */
- (BOOL)delete;

/**
 Saves metadata about the current download so it can be resumed at a later date.
 
 @return    Boolean indicating the success of the operation.
 
 @warning   This method should be run on a background thread as it could take a while to save depending on how much metdata there is.
 */
- (BOOL)save;

/**
 Starts a webserver to play local content.
 
 @param handler Block called when the torrent has finished processing and is ready to begin being played.
 */
- (void)playWithHandler:(PTTorrentStreamerReadyToPlay)handler;

/**
 Designated initialiser for the class.
 
 @param mediaMetadata   Metadata for the current download. Use `MPMediaItem` keys.
 @param downloadStatus  The `PTTorrentDownloadStatus` of the download.
 
 @warning   Only one property in the `mediaMetadata` dictionary must be set: `MPMediaItemPropertyPersistentID`. If this is not set, an exception will be raised. Also, if every `mediaMetadata` value is not an instance of NSData, NSDate, NSNumber, NSString, NSArray, or NSDictionary, an exception will be raised.
 */
- (instancetype)initWithMediaMetadata:(NSDictionary<NSString *, id> *)mediaMetadata downloadStatus:(PTTorrentDownloadStatus)downloadStatus NS_DESIGNATED_INITIALIZER;

/**
 Initialise the class from a valid `.plist` file. If the file is not valid, `nil` will be returned
 
 @param pathToPlist Local path component of the URL pointing to the `.plist` file.
 */
- (instancetype _Nullable)initFromPlist:(NSString *)pathToPlist;

/**
 Begins streaming of a torrent. To recieve status updates about the download, assign an object to the `delegate` property.
 
 @param filePathOrMagnetLink    The direct link of a locally stored `.torrent` file or a `magnet:?` link.
 
 @warning   Usage of this method is discouraged. Use `PTTorrentDownloadManager` class instead.
 */
- (void)startDownloadingFromFileOrMagnetLink:(NSString *)filePathOrMagnetLink;

#pragma mark - Hidden methods

- (void) __unavailable startStreamingFromFileOrMagnetLink:(NSString *)filePathOrMagnetLink
                                  progress:(PTTorrentStreamerProgress _Nullable)progress
                               readyToPlay:(PTTorrentStreamerReadyToPlay _Nullable)readyToPlay
                                   failure:(PTTorrentStreamerFailure _Nullable)failure;
+ (instancetype) __unavailable sharedStreamer;
- (instancetype) __unavailable init;
+ (instancetype) __unavailable new;

@end

NS_ASSUME_NONNULL_END
