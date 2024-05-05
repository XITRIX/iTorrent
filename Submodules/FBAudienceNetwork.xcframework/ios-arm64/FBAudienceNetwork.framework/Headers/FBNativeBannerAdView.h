/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBNativeAdBaseView.h>
#import <FBAudienceNetwork/FBNativeAdViewAttributes.h>
#import <FBAudienceNetwork/FBNativeBannerAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Determines the type of native banner ad template. Different views are created
 for different values of FBNativeAdBannerViewType
 */
typedef NS_ENUM(NSInteger, FBNativeBannerAdViewType) {
    /// Fixed height view, 100 points (banner equivalent)
    FBNativeBannerAdViewTypeGenericHeight100 = 1,
    /// Fixed height view, 120 points (banner equivalent)
    FBNativeBannerAdViewTypeGenericHeight120 = 2,
    /// Fixed height view, 50 points (banner equivalent)
    FBNativeBannerAdViewTypeGenericHeight50 = 5,
};

/**
 The FBNativeBannerAdView creates prebuilt native banner ad template views and manages native banner ads.
 */
FB_CLASS_EXPORT
@interface FBNativeBannerAdView : FBNativeAdBaseView

/**
 The type of the view, specifies which template to use
 */
@property (nonatomic, assign, readonly) FBNativeBannerAdViewType type;

/**
 Factory method that creates a native ad template using the given placement id and type.
 @param nativeBannerAd The native banner ad to use to create this view.
 @param type The type of this native banner ad template. For more information, consult FBNativeAdBannerViewType.
 */
+ (instancetype)nativeBannerAdViewWithNativeBannerAd:(FBNativeBannerAd *)nativeBannerAd
                                            withType:(FBNativeBannerAdViewType)type;

/**
 Factory method that creates a native ad template using the given placement id and type.
 @param nativeBannerAd The native banner ad to use to create this view.
 @param type The type of this native banner ad template. For more information, consult FBNativeAdBannerViewType.
 @param attributes The attributes to render this native ad template with.
 */
+ (instancetype)nativeBannerAdViewWithNativeBannerAd:(FBNativeBannerAd *)nativeBannerAd
                                            withType:(FBNativeBannerAdViewType)type
                                      withAttributes:(FBNativeAdViewAttributes *)attributes;

@end

@interface FBNativeAdViewAttributes (FBNativeBannerAdView)

/**
 Returns default attributes for a given type.

 @param type The type for this layout.
 */
+ (instancetype)defaultAttributesForBannerType:(FBNativeBannerAdViewType)type;

@end

NS_ASSUME_NONNULL_END
