//
//  TorrentTracker.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 02.05.2022.
//

#import "TorrentTracker_Internal.h"

@implementation TorrentTracker

- (instancetype)initWithAnnounceEntry:(lt::announce_entry)announceEntry {
    self = [self init];
    if (self) {
        _trackerUrl = [[NSString alloc] initWithFormat:@"%s", announceEntry.url.c_str()];
        _messages = @"MSG";
        _seeders = -1;
        _peers = -1;
        _leechs = -1;
        _working = announceEntry.is_working();
        _verified = announceEntry.verified;

        for (const lt::announce_endpoint &endpoint : announceEntry.endpoints) {
            _seeders = MAX(_seeders, endpoint.scrape_complete);
            _peers = MAX(_peers, endpoint.scrape_incomplete);
            _leechs = MAX(_leechs, endpoint.scrape_downloaded);
        }
    }
    return self;
}

@end
