//
//  NSObject+SessionSettings.m
//  TorrentKit
//
//  Created by Даниил Виноградов on 14.05.2022.
//

#import "SessionSettings_Internal.h"

#import "libtorrent/alert.hpp"

@implementation SessionSettings

- (instancetype)init {
    self = [super init];

    if (self) {
        _preallocateStorage = false;
    }

    return self;
}

- (lt::settings_pack)settingsPack {
    lt::settings_pack settings;

    // Must have
    settings.set_int(lt::settings_pack::alert_mask, lt::alert_category::all);

    // Settings pack
    settings.set_int(lt::settings_pack::active_limit, (int)_maxActiveTorrents);
    settings.set_int(lt::settings_pack::active_downloads, (int)_maxDownloadingTorrents);
    settings.set_int(lt::settings_pack::active_seeds, (int)_maxUploadingTorrents);

    settings.set_int(lt::settings_pack::download_rate_limit, (int)_maxDownloadSpeed);
    settings.set_int(lt::settings_pack::upload_rate_limit, (int)_maxUploadSpeed);

    return settings;
}

@end
