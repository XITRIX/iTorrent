//
//  TorrentHandle_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>
#import "TorrentHandle.h"

#import "libtorrent/torrent_handle.hpp"
#import "Session.h"

NS_ASSUME_NONNULL_BEGIN

@interface TorrentHandle ()
@property lt::torrent_handle torrentHandle;
@property NSString *torrentPath;
@property NSString *downloadPath;

-(instancetype)initWith:(lt::torrent_handle)torrentHandle inSession:(Session *)session;
@end

NS_ASSUME_NONNULL_END
