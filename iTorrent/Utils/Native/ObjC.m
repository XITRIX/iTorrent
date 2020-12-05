//
//  ObjC.m
//  iTorrent
//
//  Created by Daniil Vinogradov on 26.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#import "ObjC.h"
#import <objc/runtime.h>

@implementation ObjC

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

+ (void) oldOSPatch {
    if (@available(iOS 11, *)) {}
    else {
    // swizzle addObserver:forKeyPath:options:context:
        SEL originalSelector = @selector(addObserver:forKeyPath:options:context:);
        SEL swizzledSelector = @selector(swizzled_addObserver:forKeyPath:options:context:);

        Method originalMethod = class_getInstanceMethod(NSObject.class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self.class, swizzledSelector);
        
        BOOL didAddMethod =
                    class_addMethod(NSObject.class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(NSObject.class,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
}

static const void *ObserverKey = &ObserverKey;
- (void) swizzled_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    NSMutableSet<NSArray*> *observerSet = objc_getAssociatedObject(self, ObserverKey);
    if (observerSet == nil) {
        observerSet = [[NSMutableSet alloc] init];
        objc_setAssociatedObject(self, ObserverKey, observerSet, OBJC_ASSOCIATION_RETAIN);
    }
    // store all observer info into a set.
    [observerSet addObject:@[observer, keyPath]];
    [self swizzled_addObserver:observer forKeyPath:keyPath options:options context:context]; // this will call the origin impl
}

- (void) swizzled_dealloc {
    NSMutableSet<NSArray*> *observerSet = objc_getAssociatedObject(self, ObserverKey);
    objc_setAssociatedObject(self, ObserverKey, nil, OBJC_ASSOCIATION_RETAIN);
    for (NSArray *arr in observerSet) {
        if ([arr count] == 2) {
            // remove all observers before self is deallocated.
            [self removeObserver:arr[0] forKeyPath:arr[1]];
        }
    }
}

@end
