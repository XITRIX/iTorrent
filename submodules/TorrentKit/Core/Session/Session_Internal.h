//
//  Session_Internal.h
//  TorrentKit
//
//  Created by Даниил Виноградов on 24.04.2022.
//

#import <Foundation/Foundation.h>

#import "Session.h"
#import "SessionSettings_Internal.h"

#import "libtorrent/session.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface Session ()
@property lt::session *session;
@property (strong, nonatomic) dispatch_queue_t filesQueue;
@property (strong, nonatomic) NSThread *eventsThread;
@property (strong, nonatomic) NSHashTable *delegates;
@end

NS_ASSUME_NONNULL_END
