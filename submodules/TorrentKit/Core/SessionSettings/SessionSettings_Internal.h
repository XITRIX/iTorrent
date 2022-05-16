//
//  SessionSettings_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 14.05.2022.
//

#import <Foundation/Foundation.h>

#import "SessionSettings.h"

#import "libtorrent/settings_pack.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface SessionSettings ()
@property (readonly, nonatomic) lt::settings_pack settingsPack;
@end

NS_ASSUME_NONNULL_END
