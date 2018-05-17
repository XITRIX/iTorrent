//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include <stdio.h>
#include <stdlib.h>
#include "result_struct.h"
#include "file_struct.h"


int init_engine(const char* save_path);
Result getTorrentInfo();
void add_torrent(const char* torrent_path);
void add_torrent_with_states(const char* torrent_path, int* states);
void add_magnet(const char* magnet_link);
Files get_files_of_torrent_by_path(const char* torrent_path);
Files get_files_of_torrent_by_hash(const char* hash);
void set_torrent_files_priority(const char* torrent_hash, int* states);
void save_fast_resume();
void stop_torrent(const char* torrent_hash);
void start_torrent(const char* torrent_hash);
