/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Determines the possible tags for native ad views.
 */
typedef NS_ENUM(NSUInteger, FBNativeAdViewTag) {
    FBNativeAdViewTagIcon = 5,
    FBNativeAdViewTagTitle,
    FBNativeAdViewTagCoverImage,
    FBNativeAdViewTagSubtitle,
    FBNativeAdViewTagBody,
    FBNativeAdViewTagCallToAction,
    FBNativeAdViewTagSocialContext,
    FBNativeAdViewTagChoicesIcon,
    FBNativeAdViewTagMedia,
};

/**
 Use this category to set tags for views you are using for native ad.
 This will enable better analytics.
 */
@interface UIView (FBNativeAdViewTag)
@property (nonatomic, assign) FBNativeAdViewTag nativeAdViewTag;
@end

NS_ASSUME_NONNULL_END
