//
//  TorrentTracker_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 02.05.2022.
//

#import "TorrentTracker.h"
#import "libtorrent/announce_entry.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface TorrentTracker ()

- (instancetype)initWithAnnounceEntry:(lt::announce_entry)announceEntry;

@end

NS_ASSUME_NONNULL_END
