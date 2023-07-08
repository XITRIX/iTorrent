//
//  settings_pack_struct.h
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#ifndef settings_pack_struct_h
#define settings_pack_struct_h

enum encryption_policy_t {
    enabled,
    forced,
    disabled
};

enum proxy_type_t {
    none,
    socks4,
    socks5,
    http,
    i2p_proxy
};

typedef struct settings_pack_struct {
    int download_limit;
    int upload_limit;
    
    int max_active_torrents_limit;
    int max_upload_torrents_limit;
    int max_download_torrents_limit;

    enum encryption_policy_t encryption_policy;

    bool enable_dht;
    bool enable_lsd;
    bool enable_utp;
    bool enable_upnp;
    bool enable_natpmp;
    
    char * _Nonnull outgoing_interfaces;
    char * _Nonnull listen_interfaces;
    
    int port_range_first;
    int port_range_second;
    
    enum proxy_type_t proxy_type;
    bool proxy_requires_auth;
    char * _Nonnull proxy_hostname;
    int proxy_port;
    char * _Nonnull proxy_username;
    char * _Nonnull proxy_password;
    bool proxy_peer_connections;
} settings_pack_struct;

#endif /* settings_pack_struct_h */
