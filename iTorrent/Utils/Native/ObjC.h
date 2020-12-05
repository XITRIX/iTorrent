//
//  ObjC.h
//  iTorrent
//
//  Created by Daniil Vinogradov on 26.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#ifndef ObjC_h
#define ObjC_h

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

+ (void)oldOSPatch;

@end

#endif /* ObjC_h */
