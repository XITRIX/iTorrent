/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/***
 * This is a bridge file for Audience Network Unity SDK.
 *
 * This file may be used to build your own Audience Network iOS SDK wrapper,
 * but note that we don't support customisations of the Audience Network codebase.
 *
 ***/

#import <Foundation/Foundation.h>

#import <FBAudienceNetwork/FBAdBridgeCommon.h>
#import <FBAudienceNetwork/FBAdView.h>
#import <FBAudienceNetwork/FBInterstitialAd.h>
#import <FBAudienceNetwork/FBRewardedVideoAd.h>

typedef void (*FBAdBridgeCallback)(uint32_t uniqueId);
typedef void (*FBAdBridgeErrorCallback)(uint32_t uniqueId, char const *error);

@interface FBAdBridgeContainer : NSObject

@property (nonatomic, assign) int32_t uniqueId;

/**
 This method explicitly removes added callbacks. When the instance is deallocated, it is called automatically by SDK
 */
- (void)dispose;

@end

@interface FBAdViewBridgeContainer : FBAdBridgeContainer <FBAdViewDelegate>

@property (nonatomic, strong) FBAdView *adView;

@property (nonatomic, assign) FBAdBridgeCallback adViewDidClickCallback;
@property (nonatomic, assign) FBAdBridgeCallback adViewDidFinishHandlingClickCallback;
@property (nonatomic, assign) FBAdBridgeCallback adViewDidLoadCallback;
@property (nonatomic, assign) FBAdBridgeErrorCallback adViewDidFailWithErrorCallback;
@property (nonatomic, assign) FBAdBridgeCallback adViewWillLogImpressionCallback;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithAdView:(FBAdView *)adView withUniqueId:(int32_t)uniqueId NS_DESIGNATED_INITIALIZER;

@end

@interface FBInterstitialAdBridgeContainer : FBAdBridgeContainer <FBInterstitialAdDelegate>

@property (nonatomic, strong) FBInterstitialAd *interstitialAd;

@property (nonatomic, assign) FBAdBridgeCallback interstitialAdDidClickCallback;
@property (nonatomic, assign) FBAdBridgeCallback interstitialAdDidCloseCallback;
@property (nonatomic, assign) FBAdBridgeCallback interstitialAdWillCloseCallback;
@property (nonatomic, assign) FBAdBridgeCallback interstitialAdDidLoadCallback;
@property (nonatomic, assign) FBAdBridgeErrorCallback interstitialAdDidFailWithErrorCallback;
@property (nonatomic, assign) FBAdBridgeCallback interstitialAdWillLogImpressionCallback;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithInterstitialAd:(FBInterstitialAd *)interstitialAd
                          withUniqueId:(int32_t)uniqueId NS_DESIGNATED_INITIALIZER;

@end

@interface FBRewardedVideoAdBridgeContainer : FBAdBridgeContainer <FBRewardedVideoAdDelegate>

@property (nonatomic, strong) FBRewardedVideoAd *rewardedVideoAd;

@property (nonatomic, assign) FBAdBridgeCallback rewardedVideoAdDidClickCallback;
@property (nonatomic, assign) FBAdBridgeCallback rewardedVideoAdDidCloseCallback;
@property (nonatomic, assign) FBAdBridgeCallback rewardedVideoAdWillCloseCallback;
@property (nonatomic, assign) FBAdBridgeCallback rewardedVideoAdDidLoadCallback;
@property (nonatomic, assign) FBAdBridgeErrorCallback rewardedVideoAdDidFailWithErrorCallback;
@property (nonatomic, assign) FBAdBridgeCallback rewardedVideoAdWillLogImpressionCallback;
@property (nonatomic, assign) FBAdBridgeCallback rewardedVideoAdVideoCompleteCallback;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithRewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd
                           withUniqueId:(int32_t)uniqueId NS_DESIGNATED_INITIALIZER;

@end
