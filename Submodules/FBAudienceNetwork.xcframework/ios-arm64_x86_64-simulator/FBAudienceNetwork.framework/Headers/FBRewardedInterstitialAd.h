/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBAdExtraHint.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBRewardedInterstitialAdDelegate;

/**
 A modal view controller to represent a Facebook Rewarded Interstitial ad.
 This is a full-screen ad shown in your application.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBRewardedInterstitialAd : NSObject

/**
 Typed access to the id of the ad placement.
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 The delegate.
 */
@property (nonatomic, weak, nullable) id<FBRewardedInterstitialAdDelegate> delegate;

/**
 Returns true if the rewarded interstitial ad has been successfully loaded.
 You should check `isAdValid` before trying to show the ad.
 */
@property (nonatomic, getter=isAdValid, readonly) BOOL adValid;

/**
 FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See FBAdExtraHint for more
 details

 */
@property (nonatomic, strong, nullable) FBAdExtraHint *extraHint;

/**
 The duration of the video, as a CMTime value.  Returns kCMTimeIndefinite if no video is loaded.
 */
@property (nonatomic, assign, readonly) CMTime duration;

/**
 Initializes a FBRewardedInterstitialAd matching the given placement id.


 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID;

/**
 Initializes a FBRewardedInterstitialAd matching the given placement id and allows the publisher to set the
 reward to give to a user.


 - Parameter placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 - Parameter userID the id of the user
 - Parameter currency reward currency type
 */
- (instancetype)initWithPlacementID:(NSString *)placementID
                         withUserID:(nullable NSString *)userID
                       withCurrency:(nullable NSString *)currency;

/**
 Begins loading the FBRewardedInterstitialAd content.

 You can implement `rewardedInterstitialAdDidLoad:` and `rewardedInterstitialAd:didFailWithError:` methods of
 `FBRewardedInterstitialAdDelegate` if you would like to be notified when loading succeeds or fails.
 */
- (void)loadAd FB_DEPRECATED_WITH_MESSAGE(
    "This method will be removed in future version. Use -loadAdWithBidPayload instead."
    "See https://www.facebook.com/audiencenetwork/resources/blog/bidding-moves-from-priority-to-imperative-for-app-monetization"
    "for more details.");

/**
 Begins loading the FBRewardedInterstitialAd content from a bid payload attained through a server side bid.


 You can implement `rewardedInterstitialAdDidLoad:` and `rewardedInterstitialAd:didFailWithError:` methods of
 `FBRewardedInterstitialAdDelegate` if you would like to be notified as loading succeeds or fails.
 */
- (void)loadAdWithBidPayload:(NSString *)bidPayload;

/**
 This method allows the publisher to set the reward to give to a user. Returns NO if it was not able to set Reward Data.

 - Parameter userID the id of the user
 - Parameter currency reward currency type
 */
- (BOOL)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency;

/**
 Presents the rewarded video ad modally from the specified view controller.

 @param rootViewController The view controller that will be used to present the rewarded video ad.
 @param animated Pass YES to animate the presentation, NO otherwise.

 You can implement `rewardedInterstitialAdDidClick:` and `rewardedInterstitialAdWillClose:`
 methods of `FBRewardedInterstitialAdDelegate` if you would like to stay informed for those events.
 */
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController animated:(BOOL)animated;

@end

@protocol FBRewardedInterstitialAdDelegate <NSObject>

@optional

/**
 Sent after an ad has been clicked by the person.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 */
- (void)rewardedInterstitialAdDidClick:(FBRewardedInterstitialAd *)rewardedInterstitialAd;

/**
 Sent when an ad has been successfully loaded.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 */
- (void)rewardedInterstitialAdDidLoad:(FBRewardedInterstitialAd *)rewardedInterstitialAd;

/**
 Sent after a FBRewardedInterstitialAd object has been dismissed from the screen, returning control to your
 application.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 */
- (void)rewardedInterstitialAdDidClose:(FBRewardedInterstitialAd *)rewardedInterstitialAd;

/**
 Sent immediately before a FBRewardedInterstitialAd object will be dismissed from the screen.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 */
- (void)rewardedInterstitialAdWillClose:(FBRewardedInterstitialAd *)rewardedInterstitialAd;

/**
 Sent after a FBRewardedInterstitialAd fails to load the ad.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)rewardedInterstitialAd:(FBRewardedInterstitialAd *)rewardedInterstitialAd didFailWithError:(NSError *)error;

/**
 Sent immediately before the impression of a FBRewardedInterstitialAd object will be logged.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 */
- (void)rewardedInterstitialAdWillLogImpression:(FBRewardedInterstitialAd *)rewardedInterstitialAd;

/**
 Sent after the FBRewardedInterstitialAd object has finished playing the video successfully.
 Reward the user on this callback.

 @param rewardedInterstitialAd A FBRewardedInterstitialAd object sending the message.
 */
- (void)rewardedInterstitialAdVideoComplete:(FBRewardedInterstitialAd *)rewardedInterstitialAd;

@end

NS_ASSUME_NONNULL_END
