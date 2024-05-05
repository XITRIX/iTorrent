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
 * Please refer to FBAdSettings.h for full documentation of the API.
 *
 * This file may be used to build your own Audience Network iOS SDK wrapper,
 * but note that we don't support customisations of the Audience Network codebase.
 *
 ***/

#import <FBAudienceNetwork/FBAdBridgeCommon.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_EXTERN_C_BEGIN

FB_EXPORT void FBAdSettingsBridgeAddTestDevice(char const *deviceID);
FB_EXPORT void FBAdSettingsBridgeSetURLPrefix(char const *urlPrefix);
FB_EXPORT void FBAdSettingsBridgeSetIsChildDirected(bool isChildDirected);
FB_EXPORT void FBAdSettingsBridgeSetMixedAudience(bool mixedAudience);
FB_EXPORT void FBAdSettingsBridgeSetAdvertiserTrackingEnabled(bool advertiserTrackingEnabled);
FB_EXPORT void FBAdSettingsBridgeSetDataProcessingOptions(char const *_Nonnull options[_Nonnull], int length);
FB_EXPORT void FBAdSettingsBridgeSetDetailedDataProcessingOptions(char const *_Nonnull options[_Nonnull],
                                                                  int length,
                                                                  int country,
                                                                  int state);
FB_EXPORT char const *__nullable FBAdSettingsBridgeGetBidderToken(void);

FB_EXTERN_C_END

NS_ASSUME_NONNULL_END
