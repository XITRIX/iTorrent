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

@protocol FBInterstitialAdDelegate;

/**
 A modal view controller to represent a Facebook interstitial ad. This
 is a full-screen ad shown in your application.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBInterstitialAd : NSObject

/**
 Typed access to the id of the ad placement.
 */
@property (nonatomic, copy, readonly) NSString *placementID;
/**
 the delegate
 */
@property (nonatomic, weak, nullable) id<FBInterstitialAdDelegate> delegate;
/**
 FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See FBAdExtraHint for more
 details

 */
@property (nonatomic, strong, nullable) FBAdExtraHint *extraHint;

/**
 Experimental Feature, DO NOT USE IN PRODUCTION!
 */
@property (nonatomic) BOOL shouldShowCompanionView;

/**
 This is a method to initialize an FBInterstitialAd matching the given placement id.


 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID NS_DESIGNATED_INITIALIZER;

/**
 Returns true if the interstitial ad has been successfully loaded.


 You should check `isAdValid` before trying to show the ad.
 */
@property (nonatomic, getter=isAdValid, readonly) BOOL adValid;

/**
 Begins loading the FBInterstitialAd content.


 You can implement `interstitialAdDidLoad:` and `interstitialAd:didFailWithError:` methods
 of `FBInterstitialAdDelegate` if you would like to be notified as loading succeeds or fails.
 */
- (void)loadAd FB_DEPRECATED_WITH_MESSAGE(
    "This method will be removed in future version. Use -loadAdWithBidPayload instead."
    "See https://www.facebook.com/audiencenetwork/resources/blog/bidding-moves-from-priority-to-imperative-for-app-monetization"
    "for more details.");

/**
 Begins loading the FBInterstitialAd content from a bid payload attained through a server side bid.


 You can implement `adViewDidLoad:` and `adView:didFailWithError:` methods
 of `FBAdViewDelegate` if you would like to be notified as loading succeeds or fails.


 @param bidPayload The payload of the ad bid. You can get your bid id from Facebook bidder endpoint.
 */
- (void)loadAdWithBidPayload:(NSString *)bidPayload;

/**
 Presents the interstitial ad modally from the specified view controller.


 @param rootViewController The view controller that will be used to present the interstitial ad.


 You can implement `interstitialAdDidClick:`, `interstitialAdWillClose:` and `interstitialAdWillClose`
 methods of `FBInterstitialAdDelegate` if you would like to stay informed for thoses events
 */
- (BOOL)showAdFromRootViewController:(nullable UIViewController *)rootViewController;

@end

/**
 The methods declared by the FBInterstitialAdDelegate protocol allow the adopting delegate to respond
 to messages from the FBInterstitialAd class and thus respond to operations such as whether the
 interstitial ad has been loaded, user has clicked or closed the interstitial.
 */
@protocol FBInterstitialAdDelegate <NSObject>

@optional

/**
 Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or
 app browser will be launched.


 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd;

/**
 Sent after an FBInterstitialAd object has been dismissed from the screen, returning control
 to your application.


 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd;

/**
 Sent immediately before an FBInterstitialAd object will be dismissed from the screen.


 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd;

/**
 Sent when an FBInterstitialAd successfully loads an ad.


 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd;

/**
 Sent when an FBInterstitialAd failes to load an ad.


 @param interstitialAd An FBInterstitialAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error;

/**
 Sent immediately before the impression of an FBInterstitialAd object will be logged.


 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd;

/**
  Experimental Feature, DO NOT USE IN PRODUCTION!

 @param FBAdCompanionView should return a Companion View for the Interstitial Ad.
 */
- (void)interstitialAdCompanionViewProvider:(void (^)(FBAdCompanionView *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
