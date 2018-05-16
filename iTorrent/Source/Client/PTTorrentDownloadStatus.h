

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PTTorrentDownloadStatus) {
    PTTorrentDownloadStatusPaused = 1,
    PTTorrentDownloadStatusDownloading,
    PTTorrentDownloadStatusFinished,
    PTTorrentDownloadStatusFailed,
    PTTorrentDownloadStatusProcessing
};
