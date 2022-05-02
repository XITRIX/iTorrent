//
//  TorrentTracker.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 02.05.2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorrentTracker : NSObject

@property (readonly) NSString *trackerUrl;
@property (readonly) NSString *messages;
@property (readonly) NSInteger seeders;
@property (readonly) NSInteger peers;
@property (readonly) NSInteger leechs;
@property (readonly) BOOL working;
@property (readonly) BOOL verified;

@end

NS_ASSUME_NONNULL_END
