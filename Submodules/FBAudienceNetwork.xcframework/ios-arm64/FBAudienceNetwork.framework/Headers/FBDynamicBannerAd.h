/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBAudienceNetwork/FBAdCompanionView.h>
#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBAdExtraHint.h>
#import <FBAudienceNetwork/FBAdView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBDynamicBannerAdDelegate;

/**
 A modal view controller to represent a Facebook dynamic banner ad. This
 is a full-screen ad shown in your application.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBDynamicBannerAd : NSObject

/**
 Typed access to the id of the ad placement.
 */
@property (nonatomic, copy, readonly) NSString *placementID;
/**
 The delegate.
 */
@property (nonatomic, weak, nullable) id<FBDynamicBannerAdDelegate> delegate;
/**
 FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See FBAdExtraHint for more
 details

 */
@property (nonatomic, strong, nullable) FBAdExtraHint *extraHint;

/**
 This is a method to initialize an FBDynamicBannerAd matching the given placement id.


 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID;

/**
 This is a method to update the placement id of an FBDynamicBannerAd.


 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 */
- (void)updatePlacementID:(NSString *)placementID;

/**
 Returns true if the dynamic banner ad has been successfully loaded.


 You should check `isAdValid` before trying to show the ad.
 */
@property (nonatomic, getter=isAdValid, readonly) BOOL adValid;

/**
 Begins loading the FBDynamicBannerAd content.


 You can implement `dynamicBannerAdDidLoad:` and `dynamicBannerAd:didFailWithError:` methods
 of `FBDynamicBannerAdDelegate` if you would like to be notified as loading succeeds or fails.
 */
- (void)loadAd FB_DEPRECATED_WITH_MESSAGE(
    "This method will be removed in future version. Use -loadAdWithBidPayload instead."
    "See https://www.facebook.com/audiencenetwork/resources/blog/bidding-moves-from-priority-to-imperative-for-app-monetization"
    "for more details.");

/**
 Begins loading the FBDynamicBannerAd content from a bid payload attained through a server side bid.


 You can implement `adViewDidLoad:` and `adView:didFailWithError:` methods
 of `FBAdViewDelegate` if you would like to be notified as loading succeeds or fails.


 @param bidPayload The payload of the ad bid. You can get your bid id from Facebook bidder endpoint.
 */
- (void)loadAdWithBidPayload:(NSString *)bidPayload;

/**
 Presents the dynamic banner ad modally from the specified view controller. Must be called after loading the ad.

 @param rootViewController The view controller that will be used to present the dynamic banner ad.

 You can implement the `dynamicBannerAdDidClick:` method of `FBDynamicBannerAdDelegate` if you would like to stay
 informed for this event.
 */
- (void)showAdFromRootViewController:(nullable UIViewController *)rootViewController;

/**
 Changes the visibility of the dynamic banner ad.

 @param visible Boolean set to true in order to make the dynamic banner ad visible or false otherwise.
 */
- (void)setVisibility:(BOOL)visible;

/**
 This method removes the dynamic banner from the view. It should be called before removing its last strong reference.
 */
- (void)removeAd;

/**
 This function handles frame issues occuring when the view is layed out. It should be called on the lifecycle event
 'viewDidLayoutSubviews'.
 @param rootViewController The view controller that will be used to present the dynamic banner ad.
 */
- (void)viewDidLayoutSubviews:(nullable UIViewController *)rootViewController;

@end

/**
 The methods declared by the FBDynamicBannerAdDelegate protocol allow the adopting delegate to respond
 to messages from the FBDynamicBannerAd class and thus respond to operations such as whether the
 dynamic banner ad has been loaded, user has clicked or closed the dynamic banner.
 */
@protocol FBDynamicBannerAdDelegate <NSObject>

@optional

/**
 Sent after an ad in the FBDynamicBannerAd object is clicked. The appropriate app store view or
 app browser will be launched.


 @param dynamicBannerAd An FBDynamicBannerAd object sending the message.
 */
- (void)dynamicBannerAdDidClick:(FBDynamicBannerAd *)dynamicBannerAd;

/**
 Sent when an FBDynamicBannerAd successfully loads an ad.


 @param dynamicBannerAd An FBDynamicBannerAd object sending the message.
 */
- (void)dynamicBannerAdDidLoad:(FBDynamicBannerAd *)dynamicBannerAd;

/**
 Sent when an FBDynamicBannerAd failes to load an ad.


 @param dynamicBannerAd An FBDynamicBannerAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)dynamicBannerAd:(FBDynamicBannerAd *)dynamicBannerAd didFailWithError:(NSError *)error;

/**
 Sent immediately before the impression of an FBDynamicBannerAd object will be logged.


 @param dynamicBannerAd An FBDynamicBannerAd object sending the message.
 */
- (void)dynamicBannerAdWillLogImpression:(FBDynamicBannerAd *)dynamicBannerAd;

/**
 Sent when an FBDynamicBannerAd failes to load a fullscreen view of an ad.


 @param dynamicBannerAd An FBDynamicBannerAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)dynamicBannerAd:(FBDynamicBannerAd *)dynamicBannerAd fullscreenDidFailWithError:(NSError *)error;

/**
 When an ad is clicked, the modal view will be presented. And when the user finishes the
 interaction with the modal view and dismiss it, this message will be sent, returning control
 to the application.


 @param dynamicBannerAd An FBDynamicBannerAd object sending the message.
 */
- (void)dynamicBannerAdDidFinishHandlingClick:(FBDynamicBannerAd *)dynamicBannerAd;

@end

NS_ASSUME_NONNULL_END
