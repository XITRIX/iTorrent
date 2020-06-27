//
//  settings_pack_struct.h
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#ifndef settings_pack_struct_h
#define settings_pack_struct_h

enum proxy_type_t {
    none,
    socks4,
    socks5,
    http,
    i2p_proxy
};

typedef struct settings_pack_struct {
    bool enable_dht;
    bool enable_lsd;
    bool enable_utp;
    bool enable_upnp;
    bool enable_natpmp;
    
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
