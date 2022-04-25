//
//  TorrentFile.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import "Session.h"
#import "TorrentFile.h"

#import "libtorrent/torrent_info.hpp"
#import "libtorrent/read_resume_data.hpp"
#import "libtorrent/add_torrent_params.hpp"

@implementation TorrentFile : NSObject

- (instancetype)initWithFileAtURL:(NSURL *)fileURL {
    self = [self init];
    if (self) {
        _fileData = [NSData dataWithContentsOfURL:fileURL];
    }
    return self;
}

- (lt::torrent_info)torrent_info {
    uint8_t *buffer = (uint8_t *)[self.fileData bytes];
    size_t size = [self.fileData length];
    return lt::torrent_info((char *)buffer, (int)size);;
}

- (void)configureAddTorrentParams:(void *)params forSession:(Session *)session {
    lt::add_torrent_params *_params = (lt::add_torrent_params *)params;
    lt::torrent_info ti = [self torrent_info];

    auto ih = ti.info_hash();

    std::stringstream ss;
    ss << ih;
    std::string hashText = ss.str();

    auto data = [NSData dataWithBytes:ih.data() length:ih.size()];
    auto nspath = [session fastResumePathForInfoHash:data];
    std::string path = std::string([nspath UTF8String]);

    std::ifstream ifs(path, std::ios_base::binary);
    if (ifs.good()) {
        ifs.unsetf(std::ios_base::skipws);

        std::vector<char> buf{std::istream_iterator<char>(ifs)
        , std::istream_iterator<char>()};

        lt::error_code ec;
        auto resume = lt::read_resume_data(buf, ec);
        if (ec.value() == 0) {
            *_params = resume;
        }
    }

    _params->ti = std::make_shared<lt::torrent_info>(ti);
}

@end
