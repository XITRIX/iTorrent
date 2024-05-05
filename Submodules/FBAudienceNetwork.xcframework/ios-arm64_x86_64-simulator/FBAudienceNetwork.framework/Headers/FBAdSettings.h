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
 Audience Network error domain
 */
FB_EXPORT NSString *const FBAudienceNetworkErrorDomain;
/**
 Audience Network error FBMediaView error domain
 */
FB_EXPORT NSString *const FBAudienceNetworkMediaViewErrorDomain;

/**
 Audience Network SDK logging levels
 */
typedef NS_ENUM(NSInteger, FBAdLogLevel) {
    /// No logging
    FBAdLogLevelNone,
    /// Notifications
    FBAdLogLevelNotification,
    /// Errors only
    FBAdLogLevelError,
    /// Warnings only
    FBAdLogLevelWarning,
    /// Standard log level
    FBAdLogLevelLog,
    /// Debug logging
    FBAdLogLevelDebug,
    /// Log everything (verbose)
    FBAdLogLevelVerbose
};

/**
 Test Ad type to be injected when test mode is on
 */
typedef NS_ENUM(NSInteger, FBAdTestAdType) {
    /// This will return a random ad type when test mode is on.
    FBAdTestAdType_Default,
    /// 16x9 image ad with app install CTA option
    FBAdTestAdType_Img_16_9_App_Install,
    /// 16x9 image ad with link CTA option
    FBAdTestAdType_Img_16_9_Link,
    /// 16x9 HD video 46 sec ad with app install CTA option
    FBAdTestAdType_Vid_HD_16_9_46s_App_Install,
    /// 16x9 HD video 46 sec ad with link CTA option
    FBAdTestAdType_Vid_HD_16_9_46s_Link,
    /// 16x9 HD video 15 sec ad with app install CTA option
    FBAdTestAdType_Vid_HD_16_9_15s_App_Install,
    /// 16x9 HD video 15 sec ad with link CTA option
    FBAdTestAdType_Vid_HD_16_9_15s_Link,
    /// 9x16 HD video 39 sec ad with app install CTA option
    FBAdTestAdType_Vid_HD_9_16_39s_App_Install,
    /// 9x16 HD video 39 sec ad with link CTA option
    FBAdTestAdType_Vid_HD_9_16_39s_Link,
    /// carousel ad with square image and app install CTA option
    FBAdTestAdType_Carousel_Img_Square_App_Install,
    /// carousel ad with square image and link CTA option
    FBAdTestAdType_Carousel_Img_Square_Link,
    /// carousel ad with square video and link CTA option
    FBAdTestAdType_Carousel_Vid_Square_Link,
    /// sample playable ad with app install CTA
    FBAdTestAdType_Playable,
    /// Redirect to Facebok - Facebook Rewarded Video experience
    FBAdTestAdType_FBRV
};

@protocol FBAdLoggingDelegate;

/**
 AdSettings contains global settings for all ad controls.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBAdSettings : NSObject

/**
 Controls support for audio-only video playback when the app is backgrounded. Note that this is only supported
 when using FBMediaViewVideoRenderer, and requires corresponding support for background audio to be added to
 the app. Check Apple documentation at
 https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/creating_a_basic_video_player_ios_and_tvos/enabling_background_audio

 Default value is NO.
 */
@property (class, nonatomic, assign, getter=isBackgroundVideoPlaybackAllowed) BOOL backgroundVideoPlaybackAllowed;

/**
 When test mode is on, setting a non default value for testAdType will
 requests the specified type of ad.
 */
@property (class, nonatomic, assign) FBAdTestAdType testAdType;

/**
 When this delegate is set, logs will be redirected to the delegate instead of being logged directly to the console with
 NSLog. This can be used in combination with external logging frameworks.
 */
@property (class, nonatomic, weak, nullable) id<FBAdLoggingDelegate> loggingDelegate;

/**
 Generates bidder token that needs to be included in the server side bid request to Facebook endpoint.
 */
@property (class, nonatomic, copy, readonly) NSString *bidderToken;

/**
 Generates routing token needed for requests routing in reverse-proxy, since we don't have cookies in app environments.
 */
@property (class, nonatomic, copy, readonly) NSString *routingToken;

/**
 User's consent for advertiser tracking.
 */
+ (void)setAdvertiserTrackingEnabled:(BOOL)advertiserTrackingEnabled
    NS_DEPRECATED_IOS(
        12_0,
        17_0,
        "The setter for advertiserTrackingEnabled flag is deprecated: The setAdvertiserTrackingEnabled flag is not used for Audience Network SDK 6.15.0+ on iOS 17+ as the Audience Network SDK 6.15.0+ on iOS 17+ now relies on [ATTrackingManager trackingAuthorizationStatus] to accurately represent ATT permission for users of your app");

/*
 Returns test mode on/off.
 */
+ (BOOL)isTestMode;

/**
  Returns the hash value of the device to use test mode on.
 */
+ (NSString *)testDeviceHash;

/**
 Adds a test device.

 @param deviceHash The id of the device to use test mode, can be obtained from debug log or `+(NSString
 *)testDeviceHash` method


 Copy the current device Id from debug log and add it as a test device to get test ads. Apps
 running on Simulator will automatically get test ads. Test devices should be added before loadAdWithBidPayload: is
 called.

 */
+ (void)addTestDevice:(NSString *)deviceHash;

/**
 Add a collection of test devices. See `+addTestDevices:` for details.


 @param devicesHash The array of the device id to use test mode, can be obtained from debug log or testDeviceHash
 */
+ (void)addTestDevices:(FB_NSArrayOf(NSString *) *)devicesHash;

/**
 Clears all the added test devices
 */
+ (void)clearTestDevices;

/**
 Clears previously added test device


 @param deviceHash The id of the device using test mode, can be obtained from debug log or testDeviceHash
 */
+ (void)clearTestDevice:(NSString *)deviceHash;

/**
 Configures the ad control for treatment as child-directed.


 @param isChildDirected Indicates whether you would like your ad control to be treated as child-directed


 Note that you may have other legal obligations under the Children's Online Privacy Protection Act (COPPA).
 Please review the FTC's guidance and consult with your own legal counsel.
 */
+ (void)setIsChildDirected:(BOOL)isChildDirected
    FB_DEPRECATED_WITH_MESSAGE(
        "isChildDirected method is no longer supported in Audience Network. Use +mixedAudience instead");

/**
 Configures the ad control for treatment as mixed audience directed.
 Information for Mixed Audience Apps and Services: https://developers.facebook.com/docs/audience-network/coppa
 */
@property (class, nonatomic, assign, getter=isMixedAudience) BOOL mixedAudience;

/**
 Sets the name of the mediation service.
 If an ad provided service is mediating Audience Network in their sdk, it is required to set the name of the mediation
 service


 @param service Representing the name of the mediation that is mediation Audience Network
 */
+ (void)setMediationService:(NSString *)service;

/**
 Gets the url prefix to use when making ad requests.


 This method should never be used in production versions of your application.
 */
+ (nullable NSString *)urlPrefix;

/**
 Sets the url prefix to use when making ad requests.


 This method should never be used in production versions of your application.
 */
+ (void)setUrlPrefix:(nullable NSString *)urlPrefix;

/**
 Gets the current SDK logging level
 */
+ (FBAdLogLevel)getLogLevel;

/**
 Sets the current SDK logging level
 */
+ (void)setLogLevel:(FBAdLogLevel)level;

/// Data processing options.
/// Please read more details at https://developers.facebook.com/docs/marketing-apis/data-processing-options
///
/// @param options Processing options you would like to enable for a specific event. Current accepted value is LDU for
/// Limited Data Use.
/// @param country A country that you want to associate to this data processing option. Current accepted values are 1,
/// for the United States of America, or 0, to request that we geolocate that event.
/// @param state A state that you want to associate with this data processing option. Current accepted values are 1000,
/// for California, or 0, to request that we geolocate that event.
+ (void)setDataProcessingOptions:(NSArray<NSString *> *)options country:(NSInteger)country state:(NSInteger)state;

/// Data processing options.
/// Please read more details at https://developers.facebook.com/docs/marketing-apis/data-processing-options
///
/// @param options Processing options you would like to enable for a specific event. Current accepted value is LDU for
/// Limited Data Use.
+ (void)setDataProcessingOptions:(NSArray<NSString *> *)options;

@end

@protocol FBAdLoggingDelegate <NSObject>

- (void)logAtLevel:(FBAdLogLevel)level
      withFileName:(NSString *)fileName
    withLineNumber:(int)lineNumber
      withThreadId:(long)threadId
          withBody:(NSString *)body;

@end

NS_ASSUME_NONNULL_END
