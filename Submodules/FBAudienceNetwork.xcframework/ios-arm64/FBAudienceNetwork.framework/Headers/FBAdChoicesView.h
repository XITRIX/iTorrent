/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/UIView+FBNativeAdViewTag.h>

NS_ASSUME_NONNULL_BEGIN

@class FBAdImage;
@class FBNativeAdBase;
@class FBNativeAdViewAttributes;

/**
  FBAdChoicesView offers a simple way to display a sponsored or AdChoices icon.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBAdChoicesView : UIView

/**
  Access to the text label contained in this view.
 */
@property (nonatomic, weak, readonly, nullable) UILabel *label;

/**
  Determines whether the background mask is shown, or a transparent mask is used.
 */
@property (nonatomic, assign, getter=isBackgroundShown) BOOL backgroundShown;

/**
  Determines whether the view can be expanded upon being tapped, or defaults to fullsize. Defaults to NO.
 */
@property (nonatomic, assign, readonly, getter=isExpandable) BOOL expandable;

/**
  The native ad that provides AdChoices info, such as the image url, and click url. Setting this property updates the
  nativeAd.

 */
@property (nonatomic, weak, readwrite, nullable) FBNativeAdBase *nativeAd;

/**
  Affects background mask rendering. Setting this property updates the rendering.
 */
@property (nonatomic, assign, readwrite) UIRectCorner corner;

/**
 Affects background mask rendering. Setting this property updates the rendering.
 */
@property (nonatomic, assign, readwrite) UIEdgeInsets insets;

/**
  The view controller to present the ad choices info from. If nil, the top view controller is used.
 */
@property (nonatomic, weak, readwrite, null_resettable) UIViewController *rootViewController;

/**
 The tag for AdChoices view. Value of this property is always equal to FBNativeAdViewTagChoicesIcon.
 */
@property (nonatomic, assign, readonly) FBNativeAdViewTag nativeAdViewTag;

/**
 Initializes this view with a given native ad. Configuration is pulled from the provided native ad.


 @param nativeAd The native ad to initialize with
 */
- (instancetype)initWithNativeAd:(FBNativeAdBase *)nativeAd;

/**
 Initializes this view with a given native ad. Configuration is pulled from the provided native ad.


 @param nativeAd The native ad to initialize with
 @param expandable Controls whether view defaults to expanded or not, see ``expandable`` property documentation
 */
- (instancetype)initWithNativeAd:(FBNativeAdBase *)nativeAd expandable:(BOOL)expandable;

/**
 Initializes this view with a given native ad. Configuration is pulled from the native ad.

 @param nativeAd The native ad to initialize with
 @param expandable Controls whether view defaults to expanded or not, see ``expandable`` property documentation
 @param attributes Attributes to configure look and feel.
 */
- (instancetype)initWithNativeAd:(FBNativeAdBase *)nativeAd
                      expandable:(BOOL)expandable
                      attributes:(nullable FBNativeAdViewAttributes *)attributes;

/**
 This method updates the frame of this view using the superview, positioning the icon in the top right corner by
 default.

 */
- (void)updateFrameFromSuperview;

/**
 This method updates the frame of this view using the superview, positioning the icon in the corner specified.
 UIRectCornerAllCorners not supported.


 @param corner The corner to display this view from.
 */
- (void)updateFrameFromSuperview:(UIRectCorner)corner;

/**
 This method updates the frame of this view using the superview, positioning the icon in the corner specified with
 provided insets. UIRectCornerAllCorners not supported.


 @param corner The corner to display this view from.
 @param insets Insets to take into account when positioning the view. Only respective insets are applied to corners.
 */
- (void)updateFrameFromSuperview:(UIRectCorner)corner insets:(UIEdgeInsets)insets;

@end

NS_ASSUME_NONNULL_END
