//
//  NSObject+TorrentMagnet.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "Downloadable.h"

NS_ASSUME_NONNULL_BEGIN

@interface MagnetURI : NSObject <Downloadable>
@property (readonly, strong, nonatomic) NSURL *magnetURI;
@property (readonly) NSData *infoHash;

- (instancetype)initUnsafeWithMagnetURI:(NSURL *)magnetURI;

@end

NS_ASSUME_NONNULL_END
