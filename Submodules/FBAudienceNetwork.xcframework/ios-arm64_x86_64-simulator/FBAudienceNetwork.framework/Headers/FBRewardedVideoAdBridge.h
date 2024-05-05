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
 * Please refer to FBRewardedVideoAd.h and FBAdExtraHint.h for full documentation of the API.
 *
 * This file may be used to build your own Audience Network iOS SDK wrapper,
 * but note that we don't support customisations of the Audience Network codebase.
 *
 ***/

#import <FBAudienceNetwork/FBAdBridgeCommon.h>

FB_EXTERN_C_BEGIN

FB_EXPORT int32_t FBRewardedVideoAdBridgeCreate(char const *placementID);
FB_EXPORT int32_t FBRewardedVideoAdBridgeCreateWithReward(char const *placementID,
                                                          char const *userID,
                                                          char const *currency);

FB_EXPORT int32_t FBRewardedVideoAdBridgeLoad(int32_t uniqueId);
FB_EXPORT int32_t FBRewardedVideoAdBridgeLoadWithBidPayload(int32_t uniqueId, char *bidPayload);

FB_EXPORT bool FBRewardedVideoAdBridgeIsValid(int32_t uniqueId);
FB_EXPORT char const *FBRewardedVideoAdBridgeGetPlacementId(int32_t uniqueId);
FB_EXPORT bool FBRewardedVideoAdBridgeShow(int32_t uniqueId);
FB_EXPORT bool FBRewardedVideoAdBridgeShowAnimated(int32_t uniqueId, bool isAnimated);
FB_EXPORT void FBRewardedVideoAdBridgeSetExtraHints(int32_t uniqueId, char const *extraHints);
FB_EXPORT void FBRewardedVideoAdBridgeRelease(int32_t uniqueId);

FB_EXPORT void FBRewardedVideoAdBridgeOnLoad(int32_t uniqueId, FBAdBridgeCallback callback);
FB_EXPORT void FBRewardedVideoAdBridgeOnImpression(int32_t uniqueId, FBAdBridgeCallback callback);
FB_EXPORT void FBRewardedVideoAdBridgeOnClick(int32_t uniqueId, FBAdBridgeCallback callback);
FB_EXPORT void FBRewardedVideoAdBridgeOnError(int32_t uniqueId, FBAdBridgeErrorCallback callback);
FB_EXPORT void FBRewardedVideoAdBridgeOnDidClose(int32_t uniqueId, FBAdBridgeCallback callback);
FB_EXPORT void FBRewardedVideoAdBridgeOnWillClose(int32_t uniqueId, FBAdBridgeCallback callback);
FB_EXPORT void FBRewardedVideoAdBridgeOnVideoComplete(int32_t uniqueId, FBAdBridgeCallback callback);

FB_EXTERN_C_END
