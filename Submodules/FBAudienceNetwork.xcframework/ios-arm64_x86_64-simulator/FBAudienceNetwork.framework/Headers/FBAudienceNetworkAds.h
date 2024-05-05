/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBAudienceNetwork/FBAdDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 FBAdInitSettings is an object to incapsulate all the settings you can pass to SDK on initialization call.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBAdInitSettings : NSObject

/**
 Designated initializer for FBAdInitSettings
 If an ad provided service is mediating Audience Network in their sdk, it is required to set the name of the mediation
 service

 @param placementIDs An array of placement identifiers.
 @param mediationService String to identify mediation provider.
 */
- (instancetype)initWithPlacementIDs:(NSArray<NSString *> *)placementIDs mediationService:(NSString *)mediationService;

/**
 An array of placement identifiers.
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *placementIDs;

/**
 String to identify mediation provider.
 */
@property (nonatomic, copy, readonly) NSString *mediationService;

@end

/**
 FBAdInitResults is an object to incapsulate all the results you'll get as a result of SDK initialization call.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBAdInitResults : NSObject

/**
 Boolean which says whether initialization was successful
 */
@property (nonatomic, assign, readonly, getter=isSuccess) BOOL success;

/**
 Message which provides more details about initialization result
 */
@property (nonatomic, copy, readonly) NSString *message;

@end

/**
  FBAudienceNetworkAds is an entry point to AN SDK.
 */
typedef NS_ENUM(NSInteger, FBAdFormatTypeName) {
    FBAdFormatTypeNameUnknown = 0,
    FBAdFormatTypeNameBanner,
    FBAdFormatTypeNameInterstitial,
    FBAdFormatTypeNameNative,
    FBAdFormatTypeNameNativeBanner,
    FBAdFormatTypeNameRewardedVideo,
};

FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBAudienceNetworkAds : NSObject

/**
 Initialize Audience Network SDK at any given point of time. It will be called automatically with default settigs when
 you first touch AN related code otherwise.

 @param settings The settings to initialize with
 @param completionHandler The block which will be called when initialization finished
 */
+ (void)initializeWithSettings:(nullable FBAdInitSettings *)settings
             completionHandler:(nullable void (^)(FBAdInitResults *results))completionHandler;

+ (void)handleDeeplink:(NSURL *)deeplink;

@end

NS_ASSUME_NONNULL_END
