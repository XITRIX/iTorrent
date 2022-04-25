//
//  TorrentFile_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 25.04.2022.
//

#import "TorrentFile.h"
#import "FileEntry_Internal.h"

#import "libtorrent/torrent_info.hpp"
#import "libtorrent/torrent_handle.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface TorrentFile ()
@property (readonly, nullable) NSMutableArray<NSNumber *> *priorities;

- (lt::torrent_info)torrent_info;
@end

NS_ASSUME_NONNULL_END

