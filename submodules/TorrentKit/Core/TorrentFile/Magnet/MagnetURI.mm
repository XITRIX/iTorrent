//
//  NSObject+TorrentMagnet.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import "MagnetURI.h"

#import "libtorrent/torrent_info.hpp"
#import "libtorrent/magnet_uri.hpp"

@implementation MagnetURI : NSObject

- (instancetype)initUnsafeWithMagnetURI:(NSURL *)magnetURI {
    self = [self init];
    if (self) {
        _magnetURI = magnetURI;
        if (!self.isMagnetLinkValid) { return NULL; }
    }
    return self;
}

- (BOOL)isMagnetLinkValid {
    lt::error_code ec;
    lt::string_view uri = lt::string_view([self.magnetURI.absoluteString UTF8String]);
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
