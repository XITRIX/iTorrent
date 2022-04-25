//
//  STTorrentState.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TorrentHandleState) {
    TorrentHandleStateCheckingFiles,
    TorrentHandleStateDownloadingMetadata,
    TorrentHandleStateDownloading,
    TorrentHandleStateFinished,
    TorrentHandleStateSeeding,
    TorrentHandleStateAllocating,
    TorrentHandleStateCheckingResumeData,
    TorrentHandleStatePaused
} NS_SWIFT_NAME(TorrentHandle.State);
