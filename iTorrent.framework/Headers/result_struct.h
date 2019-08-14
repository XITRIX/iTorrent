//
//  result_struct.h
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef result_struct_h
#define result_struct_h

typedef struct TorrentInfo {
    char * _Nonnull name;
    char * _Nonnull state;
    char * _Nonnull hash;
    char * _Nonnull creator;
    char * _Nonnull comment;
    float progress;
    long long total_wanted;
    long long total_wanted_done;
    int download_rate;
    int upload_rate;
    long long total_download;
    long long total_upload;
    int num_seeds;
    int num_peers;
    long long total_size;
    long long total_done;
    time_t creation_date;
    int is_paused;
    int is_finished;
    int is_seed;
    int has_metadata;
    int sequential_download;
    int num_pieces;
    int * _Nonnull pieces;
} TorrentInfo;

typedef struct Result {
    int count;
    TorrentInfo * _Nonnull torrents;
} Result;

#endif /* result_struct_h */
