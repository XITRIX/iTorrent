//
//  ExceptionCatcher.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 02.05.2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjC : NSObject {}

+ (void) tryBlock:(void(^)(void))block;

@end
NS_ASSUME_NONNULL_END
