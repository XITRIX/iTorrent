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

NS_ASSUME_NONNULL_BEGIN

@protocol FBNativeAdDelegate;

/**
 The FBNativeAd represents ad metadata to allow you to construct custom ad views.
 See the AdUnitsSample in the sample apps section of the Audience Network framework.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBNativeAd : FBNativeAdBase

/**
 the delegate
 */
@property (nonatomic, weak, nullable) id<FBNativeAdDelegate> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID;

/**
 This is a method to associate a FBNativeAd with the UIView you will use to display the native ads.


 @param view The UIView you created to render all the native ads data elements.
 @param mediaView The FBMediaView you created to render the media (cover image / video / carousel)
 @param iconView The FBMediaView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information) or the in-app browser. If nil is passed, the top view controller currently shown
 will be used. The whole area of the UIView will be clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                         mediaView:(FBMediaView *)mediaView
                          iconView:(nullable FBMediaView *)iconView
                    viewController:(nullable UIViewController *)viewController;

/**
 This is a method to associate FBNativeAd with the UIView you will use to display the native ads
 and set clickable areas.


 @param view The UIView you created to render all the native ads data elements.
 @param mediaView The FBMediaView you created to render the media (cover image / video / carousel)
 @param iconView The FBMediaView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information). If nil is passed, the top view controller currently shown will be used.
 @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                         mediaView:(FBMediaView *)mediaView
                          iconView:(nullable FBMediaView *)iconView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

/**
 This is a method to associate a FBNativeAd with the UIView you will use to display the native ads.


 @param view The UIView you created to render all the native ads data elements.
 @param mediaView The FBMediaView you created to render the media (cover image / video / carousel)
 @param iconImageView The UIImageView you created to render the icon
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information) or the in-app browser. If nil is passed, the top view controller currently shown
 will be used. The whole area of the UIView will be clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                         mediaView:(FBMediaView *)mediaView
                     iconImageView:(nullable UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController;

/**
 This is a method to associate FBNativeAd with the UIView you will use to display the native ads
 and set clickable areas.


 @param view The UIView you created to render all the native ads data elements.
 @param mediaView The FBMediaView you created to render the media (cover image / video / carousel)
 @param iconImageView The UIImageView you created to render the icon. Image will be set
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information). If nil is passed, the top view controller currently shown will be used.
 @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(UIView *)view
                         mediaView:(FBMediaView *)mediaView
                     iconImageView:(nullable UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

/**
 This method downloads all media for the ad (adChoicesIcon, icon, image, video).
 It should be called only when mediaCachePolicy is set to FBNativeAdsCachePolicyNone.
 */
- (void)downloadMedia;

@end

/**
 The methods declared by the FBNativeAdDelegate protocol allow the adopting delegate to respond to messages
 from the FBNativeAd class and thus respond to operations such as whether the native ad has been loaded.
 */
@protocol FBNativeAdDelegate <NSObject>

@optional

/**
 Sent when a FBNativeAd has been successfully loaded.


 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd;

/**
 Sent when a FBNativeAd has succesfully downloaded all media
 */
- (void)nativeAdDidDownloadMedia:(FBNativeAd *)nativeAd;

/**
 Sent immediately before the impression of a FBNativeAd object will be logged.


 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd;

/**
 Sent when a FBNativeAd is failed to load.


 @param nativeAd A FBNativeAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error;

/**
 Sent after an ad has been clicked by the person.


 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidClick:(FBNativeAd *)nativeAd;

/**
 When an ad is clicked, the modal view will be presented. And when the user finishes the
 interaction with the modal view and dismiss it, this message will be sent, returning control
 to the application.


 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidFinishHandlingClick:(FBNativeAd *)nativeAd;

@end

NS_ASSUME_NONNULL_END
