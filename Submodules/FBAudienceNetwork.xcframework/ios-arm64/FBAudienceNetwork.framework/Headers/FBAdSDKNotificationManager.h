/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBAdSDKNotificationListener <NSObject>

/**
Method to be called when some specific SDK event will happens

@param event event type. Currently suuported following events:
  "impression" happens every time when AD got an inpression recorded on the SDK
@param eventData is a payload associated with the event.

Method would be called on the main queue when the SDK event happens.
*/
- (void)onFBAdEvent:(NSString *)event eventData:(NSDictionary<NSString *, NSString *> *)eventData;

@end

@interface FBAdSDKNotificationManager : NSObject

/**
 Adds a listener to SDK events

@param listener The listener to receive notification when the event happens

Note that SDK will hold a weak reference to listener object
*/
+ (void)addFBAdSDKNotificationListener:(id<FBAdSDKNotificationListener>)listener;

/**
 Adds a listener to SDK events

@param listener The listener to be removed from notification list.

You can call this method when you no longer want to receive SDK notifications.
*/
+ (void)removeFBAdSDKNotificationListener:(id<FBAdSDKNotificationListener>)listener;

@end

NS_ASSUME_NONNULL_END
