/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBNativeAd.h>
#import <FBAudienceNetwork/FBNativeAdBaseView.h>
#import <FBAudienceNetwork/FBNativeAdViewAttributes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Determines the type of native ad template. Different views are created
 for different values of FBNativeAdViewType
 */
typedef NS_ENUM(NSInteger, FBNativeAdViewType) {
    /// Fixed height view, 300 points
    FBNativeAdViewTypeGenericHeight300 = 3,
    /// Fixed height view, 400 points
    FBNativeAdViewTypeGenericHeight400 = 4,
    /// Dynamic height, will be rendered to make the best use of the size set.
    FBNativeAdViewTypeDynamic = 6,
};

/**
 The FBNativeAdView creates prebuilt native ad template views and manages native ads.
 */
FB_CLASS_EXPORT
@interface FBNativeAdView : FBNativeAdBaseView

/**
 The type of the view, specifies which template to use
 */
@property (nonatomic, assign, readonly) FBNativeAdViewType type;

/**
 This is a method to create a native ad template using the given native ad and using default ad view attributes.
 @param nativeAd The native ad to use to create this view.
 */
+ (instancetype)nativeAdViewWithNativeAd:(FBNativeAd *)nativeAd;

/**
 This is a method to create a native ad template using the given native ad and ad view attributes.
 @param nativeAd The native ad to use to create this view.
 */
+ (instancetype)nativeAdViewWithNativeAd:(FBNativeAd *)nativeAd withAttributes:(FBNativeAdViewAttributes *)attributes;

/**
 This is a method to create a native ad template using the given placement id and type.
 @param nativeAd The native ad to use to create this view.
 @param type The type of this native ad template. For more information, consult FBNativeAdViewType.
 */
+ (instancetype)nativeAdViewWithNativeAd:(FBNativeAd *)nativeAd withType:(FBNativeAdViewType)type;

/**
 This is a method to create a native ad template using the given placement id and type.
 @param nativeAd The native ad to use to create this view.
 @param type The type of this native ad template. For more information, consult FBNativeAdViewType.
 @param attributes The attributes to render this native ad template with.
 */
+ (instancetype)nativeAdViewWithNativeAd:(FBNativeAd *)nativeAd
                                withType:(FBNativeAdViewType)type
                          withAttributes:(FBNativeAdViewAttributes *)attributes;

@end

@interface FBNativeAdViewAttributes (FBNativeAdView)

/**
 Returns default attributes for a given type.

 @param type The type for this layout.
 */
+ (instancetype)defaultAttributesForType:(FBNativeAdViewType)type;

@end

NS_ASSUME_NONNULL_END
