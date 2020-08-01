//
//  peer_struct.h
//  iTorrent
//
//  Created by Daniil Vinogradov on 27.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#ifndef peer_struct_h
#define peer_struct_h

typedef struct Peer {
    int port;
    char * _Nonnull client;
    long long total_download;
    long long total_upload;
    int up_speed;
    int down_speed;
    int connection_type;
    int progress;
    int progress_ppm;
    char * _Nonnull address;
} Peer;

typedef struct PeerResult {
    int count;
    Peer * _Nonnull peers;
} PeerResult;

#endif /* peer_struct_h */
