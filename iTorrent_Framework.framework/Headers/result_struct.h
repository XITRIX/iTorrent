//
//  result_struct.h
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef result_struct_h
#define result_struct_h

typedef struct Result {
    int count;
    char * _Nullable * _Nonnull name;
    char * _Nullable * _Nonnull state;
    char * _Nullable * _Nonnull hash;
    char * _Nullable * _Nonnull creator;
    char * _Nullable * _Nonnull comment;
    float * _Nonnull progress;
    long long * _Nonnull total_wanted;
    long long * _Nonnull total_wanted_done;
    int * _Nonnull download_rate;
    int * _Nonnull upload_rate;
    long long * _Nonnull total_download;
    long long * _Nonnull total_upload;
    int * _Nonnull num_seeds;
    int * _Nonnull num_peers;
    long long * _Nonnull total_size;
    long long * _Nonnull total_done;
    time_t * _Nonnull creation_date;
    int * _Nonnull is_paused;
    int * _Nonnull is_finished;
    int * _Nonnull is_seed;
	int * _Nonnull has_metadata;
} Result;

#endif /* result_struct_h */
