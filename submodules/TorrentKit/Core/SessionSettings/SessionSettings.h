//
//  SessionSettings.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 14.05.2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Session.Settings)
@interface SessionSettings : NSObject

@property (readwrite, nonatomic) BOOL preallocateStorage;

@property (readwrite, nonatomic) NSInteger maxActiveTorrents;
@property (readwrite, nonatomic) NSInteger maxDownloadingTorrents;
@property (readwrite, nonatomic) NSInteger maxUploadingTorrents;

@property (readwrite, nonatomic) NSUInteger maxDownloadSpeed;
@property (readwrite, nonatomic) NSUInteger maxUploadSpeed;

@end

NS_ASSUME_NONNULL_END
