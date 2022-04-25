//
//  NSData+Sha1Hash.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import "NSData+Sha1Hash.h"

@implementation NSData (SHA1)

- (instancetype)initWith:(lt::sha1_hash)hash {
    return [[NSData alloc] initWithBytes:hash.data() length:hash.size()];
}

@end

