/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBMediaView.h>
#import <FBAudienceNetwork/UIView+FBNativeAdViewTag.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_CLASS_EXPORT
FB_DEPRECATED_WITH_MESSAGE("This class will be removed in a future release. Use FBMediaView instead.")
@interface FBAdIconView : FBMediaView

/**
 The tag for the icon view. Value of this property is always equal to FBNativeAdViewTagIcon.
 */
@property (nonatomic, assign, readonly) FBNativeAdViewTag nativeAdViewTag;

@end

NS_ASSUME_NONNULL_END
