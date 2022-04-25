//
//  NSData+Hex.m
//  SwiftyTorrent
//
//  Created by Danylo Kostyshyn on 7/14/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

#import "NSData+Hex.h"

@implementation NSData (Hex)

- (NSString *)hexString {
    const uint8_t *buffer = (const uint8_t *)self.bytes;
    NSMutableString *hexString = [[NSMutableString alloc] initWithCapacity:(self.length * 2)];
    for (int i=0; i<self.length; i++) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }
    return hexString;
}

@end

