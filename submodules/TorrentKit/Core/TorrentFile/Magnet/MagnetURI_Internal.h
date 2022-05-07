//
//  MagnetURI_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 08.05.2022.
//

#import "MagnetURI.h"
#import "FileEntry_Internal.h"

#import "libtorrent/torrent_info.hpp"
#import "libtorrent/magnet_uri.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface MagnetURI ()
@property (readwrite) lt::add_torrent_params torrentParams;
@end

NS_ASSUME_NONNULL_END

