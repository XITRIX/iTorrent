//
//  TorrentFile.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "Downloadable.h"
#import "FileEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface TorrentFile : NSObject <Downloadable>
@property (readonly, strong, nonatomic) NSData *fileData;
@property (readonly) NSString *name;
@property (readonly) NSArray<FileEntry *> *files;

- (instancetype)initWithFileAtURL:(NSURL *)fileURL;

- (void)setFilePriority:(FilePriority)priority at:(NSInteger)fileIndex;


@end

NS_ASSUME_NONNULL_END
