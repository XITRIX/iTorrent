//
//  FileEntry_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 25.04.2022.
//

#import "FileEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileEntry ()
@property (readwrite, nonatomic) BOOL isPrototype;
@property (readwrite, strong, nonatomic) NSString *name;
@property (readwrite, strong, nonatomic) NSString *path;
@property (readwrite, nonatomic) uint64_t size;
@property (readwrite, nonatomic) uint64_t downloaded;
@property (readwrite, nonatomic) FilePriority priority;
@property (readwrite, nonatomic) uint64_t begin_idx;
@property (readwrite, nonatomic) uint64_t end_idx;
@property (readwrite, nonatomic) NSInteger num_pieces;
@property (readwrite, nonatomic) NSArray<NSNumber *> *pieces;
@end

NS_ASSUME_NONNULL_END
