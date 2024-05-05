/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBAdExtraHint.h>
#import <FBAudienceNetwork/FBNativeAd.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @protocol FBNativeAdsManagerDelegate


 Messages from FBNativeAdsManager indicating success or failure loading ads.
 */
@protocol FBNativeAdsManagerDelegate <NSObject>

/**
 When the FBNativeAdsManager has finished loading a batch of ads this message will be sent. A batch of ads may be
 loaded in response to calling loadAds or due to an automatic refresh by the FBNativeAdsManager. At the point this
 message is fired all of the native ads will already be loaded and will not hence send their own nativeAdLoad: or
 nativeAd:didFailWithError: message.
 */
- (void)nativeAdsLoaded;

/**
 When the FBNativeAdsManager has reached a failure while attempting to load a batch of ads this message will be sent to
 the application.
 @param error An NSError object with information about the failure.
 */
- (void)nativeAdsFailedToLoadWithError:(NSError *)error;

@end

/**
 This class provides a mechanism to fetch a set of ads and then use them within your application. The recommended usage
 is to call nextNativeAd: at the moment when you are about to render an ad. The native ads manager supports giving out
 as many ads as needed by cloning over the set of ads it got back from the server which can be useful for feed
 scenarios.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBNativeAdsManager : NSObject

/**
 The delegate
 */
@property (nonatomic, weak, nullable) id<FBNativeAdsManagerDelegate> delegate;

/**
 Set the native ads manager caching policy. This controls which media from the native ads are cached before the native
 ads manager calls nativeAdsLoaded on its delegate. The default is to not block on caching.
 */
@property (nonatomic, assign) FBNativeAdsCachePolicy mediaCachePolicy;

/**
 Number of unique native ads that can be accessed through nextNativeAd:. This is not valid until the nativeAdsLoaded:
 message has been sent.
 */
@property (nonatomic, assign, readonly) NSUInteger uniqueNativeAdCount;

/**
 Returns YES after nativeAdsLoaded: message has been sent.
 */
@property (nonatomic, assign, getter=isValid, readonly) BOOL valid;

/**
 FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See FBAdExtraHint for more
 details

 */
@property (nonatomic, strong, nullable) FBAdExtraHint *extraHint;

/**
 Initializes the native ads manager.


 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 @param numAdsRequested The number of ads you would like the native ads manager to retrieve.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID
                 forNumAdsRequested:(NSUInteger)numAdsRequested NS_DESIGNATED_INITIALIZER;

/**
  The method that kicks off the loading of ads. It may be called again in the future to refresh the ads manually.
 */
- (void)loadAds;

/**
 By default the native ads manager will refresh its ads periodically. This does not mean that any ads which are shown
 in the application's UI will be refreshed but simply that calling nextNativeAd: may return different ads at different
 times. This method disables that functionality.
 */
- (void)disableAutoRefresh;

/**
 Retrieve the next native ad to be used from the batch. It is highly recommended that the caller wait until immediately
 before rendering the ad content to call this method to ensure the best ad for the given context is used. If more than
 uniqueNativeAdCount ads are requested cloned ads will be returned. Periodically the native ads manager will refresh and
 new ads will be returned.


 @return A FBNativeAd which is loaded and ready to be used.
 */
@property (nonatomic, readonly, strong, nullable) FBNativeAd *nextNativeAd;

@end

NS_ASSUME_NONNULL_END
