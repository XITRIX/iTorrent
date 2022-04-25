//
//  FileEntry.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 25.04.2022.
//

#import <Foundation/Foundation.h>

#import "FilePriority.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileEntry : NSObject
@property (readonly, nonatomic) BOOL isPrototype;
@property (readonly, strong, nonatomic) NSString *name;
@property (readonly, strong, nonatomic) NSString *path;
@property (readonly, nonatomic) uint64_t size;
@property (readonly, nonatomic) uint64_t downloaded;
@property (readonly, nonatomic) FilePriority priority;
@property (readonly, nonatomic) uint64_t begin_idx;
@property (readonly, nonatomic) uint64_t end_idx;
@property (readonly, nonatomic) NSInteger num_pieces;
@property (readonly, nonatomic) NSArray<NSNumber *> *pieces;
@end

NS_ASSUME_NONNULL_END
