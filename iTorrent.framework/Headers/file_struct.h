//
//  file_struct.h
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef file_struct_h
#define file_struct_h

typedef struct File {
    char * _Nonnull file_name;
    char * _Nonnull file_path;
    long long file_size;
    long long file_downloaded;
    int file_priority;
    long long begin_idx;
    long long end_idx;
    int num_pieces;
    int * _Nonnull pieces;
} File;

typedef struct Files {
    int error;
    int size;
    char* _Nonnull title;
    File* _Nonnull files;
} Files;

typedef struct Trackers {
	int size;
    char * _Nonnull * _Nonnull tracker_url;
    char * _Nonnull * _Nonnull messages;
    int * _Nonnull seeders;
    int * _Nonnull peers;
    int * _Nonnull leechs;
    int * _Nonnull working;
    int * _Nonnull verified;
} Trackers;
#endif /* file_struct_h */
