//
//  Downloadable+Sha1Hash_NSData.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "libtorrent/sha1_hash.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface NSData (SHA1)

- (instancetype)initWith:(lt::sha1_hash)hash;

@end

NS_ASSUME_NONNULL_END
