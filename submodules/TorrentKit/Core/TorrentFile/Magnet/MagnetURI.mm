//
//  NSObject+TorrentMagnet.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import "MagnetURI_Internal.h"

@implementation MagnetURI : NSObject

- (instancetype)initUnsafeWithMagnetURI:(NSURL *)magnetURI {
    self = [self init];
    if (self) {
        _magnetURI = magnetURI;

        lt::error_code ec;
        _torrentParams = lt::parse_magnet_uri([_magnetURI.absoluteString UTF8String], ec);
        if (ec.failed()) { return NULL; }
    }
    return self;
}

- (NSData *)infoHash {
    auto ih = _torrentParams.info_hash;
    return [NSData dataWithBytes:ih.data() length:ih.size()];
}

- (BOOL)isMagnetLinkValid {
    lt::error_code ec;
    lt::string_view uri = lt::string_view([_magnetURI.absoluteString UTF8String]);
    lt::parse_magnet_uri(uri, ec);
    return !ec.failed();
}

- (void)configureAddTorrentParams:(void *)params forSession:(Session *)session {
    lt::add_torrent_params *_params = (lt::add_torrent_params *)params;
    lt::error_code ec;
    lt::string_view uri = lt::string_view([self.magnetURI.absoluteString UTF8String]);
    lt::parse_magnet_uri(uri, (*_params), ec);
    if (ec.failed()) {
        NSLog(@"%s, error_code: %s", __FUNCTION__, ec.message().c_str());
    }
}

- (void)configureAfterAdded:(TorrentHandle *)torrentHandle { }

@end
