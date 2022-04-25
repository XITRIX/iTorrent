//
//  TorrentFilePriority.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 25.04.2022.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, FilePriority) {
    FilePriorityDontDownload = 0,
    FilePriorityDefaultPriority = 4,
    FilePriorityLowPriority = 1,
    FilePriorityTopPriority = 7
} NS_SWIFT_NAME(FileEntry.Priority);
