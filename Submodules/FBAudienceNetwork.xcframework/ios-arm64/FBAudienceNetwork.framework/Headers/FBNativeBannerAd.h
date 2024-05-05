/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBAdImage.h>
#import <FBAudienceNetwork/FBAdSettings.h>
#import <FBAudienceNetwork/FBNativeAdBase.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBNativeBannerAdDelegate;

@class FBMediaView;

/**
 The FBNativeBannerAd represents ad metadata to allow you to construct custom ad views.
 See the AdUnitsSample in the sample apps section of the Audience Network framework.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBNativeBannerAd : FBNativeAdBase

@property (nonatomic, weak, nullable) id<FBNativeBannerAdDelegate> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID;

/**
 This is a method to associate a FBNativeBannerAd with the UIView you will use to display the native ads.

 @param view The UIView you created to render all the native ads data elements.
 @param iconView The FBMediaView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information) or the in-app browser. If nil is passed, the top view controller currently shown
 will be used.

 The whole area of the UIView will be clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                          iconView:(FBMediaView *)iconView
                    viewController:(nullable UIViewController *)viewController;

/**
 This is a method to associate FBNativeBannerAd with the UIView you will use to display the native ads
 and set clickable areas.

 @param view The UIView you created to render all the native ads data elements.
 @param iconView The FBMediaView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information). If nil is passed, the top view controller currently shown will be used.
 @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                          iconView:(FBMediaView *)iconView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

/**
 This is a method to associate a FBNativeBannerAd with the UIView you will use to display the native ads.

 @param view The UIView you created to render all the native ads data elements.
 @param iconImageView The UIImageView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information) or the in-app browser. If nil is passed, the top view controller currently shown
 will be used.


 The whole area of the UIView will be clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                     iconImageView:(UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController;

/**
 This is a method to associate FBNativeBannerAd with the UIView you will use to display the native ads
 and set clickable areas.

 @param view The UIView you created to render all the native ads data elements.
 @param iconImageView The UIImageView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information). If nil is passed, the top view controller currently shown will be used.
 @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                     iconImageView:(UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

/**
 This is a method to use to download all media for the ad (adChoicesIcon, icon).
 This is only needed to be called if the mediaCachePolicy is set to FBNativeAdsCachePolicyNone.
 */
- (void)downloadMedia;

@end

/**
 The methods declared by the FBNativeBannerAdDelegate protocol allow the adopting delegate to respond to messages
 from the FBNativeBannerAd class and thus respond to operations such as whether the native banner ad has been loaded.
 */
@protocol FBNativeBannerAdDelegate <NSObject>

@optional

/**
 Sent when a FBNativeBannerAd has been successfully loaded.

 @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdDidLoad:(FBNativeBannerAd *)nativeBannerAd;

/**
 Sent when a FBNativeBannerAd has succesfully downloaded all media
 */
- (void)nativeBannerAdDidDownloadMedia:(FBNativeBannerAd *)nativeBannerAd;

/**
 Sent immediately before the impression of a FBNativeBannerAd object will be logged.

 @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdWillLogImpression:(FBNativeBannerAd *)nativeBannerAd;

/**
 Sent when a FBNativeBannerAd is failed to load.

 @param nativeBannerAd A FBNativeBannerAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)nativeBannerAd:(FBNativeBannerAd *)nativeBannerAd didFailWithError:(NSError *)error;

/**
 Sent after an ad has been clicked by the person.

 @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdDidClick:(FBNativeBannerAd *)nativeBannerAd;

/**
 When an ad is clicked, the modal view will be presented. And when the user finishes the
 interaction with the modal view and dismiss it, this message will be sent, returning control
 to the application.

 @param nativeBannerAd A FBNativeBannerAd object sending the message.
 */
- (void)nativeBannerAdDidFinishHandlingClick:(FBNativeBannerAd *)nativeBannerAd;

@end

NS_ASSUME_NONNULL_END
