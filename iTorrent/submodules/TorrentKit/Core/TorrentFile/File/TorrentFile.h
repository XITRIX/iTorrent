//
//  TorrentFile.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "Downloadable.h"

NS_ASSUME_NONNULL_BEGIN

@interface TorrentFile : NSObject <Downloadable>
@property (readonly, strong, nonatomic) NSData *fileData;

- (instancetype)initWithFileAtURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
