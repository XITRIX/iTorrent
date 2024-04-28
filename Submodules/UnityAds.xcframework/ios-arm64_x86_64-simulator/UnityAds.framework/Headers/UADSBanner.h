#include <UIKit/UIKit.h>
#include <UnityAds/UnityAdsBannerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An enumeration for the various ways to position the Unity Ads banner placement.
 */
typedef NS_ENUM (NSInteger, UnityAdsBannerPosition) {
    kUnityAdsBannerPositionTopLeft,
    kUnityAdsBannerPositionTopCenter,
    kUnityAdsBannerPositionTopRight,
    kUnityAdsBannerPositionBottomLeft,
    kUnityAdsBannerPositionBottomCenter,
    kUnityAdsBannerPositionBottomRight,
    kUnityAdsBannerPositionCenter,
    kUnityAdsBannerPositionNone
};

/**
 * UnityAdsBanner is a static class for handling showing and hiding the Unity Ads banner.
 */

@interface UnityAdsBanner : NSObject
/*
 * Loads the banner with the given placement.
 * @param placementId The placement ID, as defined in the Unity Ads admin tools.
 */
+ (void)loadBanner: (nonnull NSString *)placementId __attribute__((deprecated));

/**
 * Destroys the current banner placement.
 */
+ (void)                                destroy __attribute__((deprecated));

+ (void)setBannerPosition: (UnityAdsBannerPosition)bannerPosition __attribute__((deprecated));

/**
 *  Provides the currently assigned `UnityAdsBannerDelegate`.
 *
 *  @return The current `UnityAdsBannerDelegate`.
 */
+ (nullable id <UnityAdsBannerDelegate>)getDelegate __attribute__((deprecated));

/**
 *  Asigns the banner delegate.
 *
 *  @param delegate The new `UnityAdsBannerDelegate' for UnityAds to send banner callbacks to.
 */
+ (void)setDelegate: (id <UnityAdsBannerDelegate>)delegate __attribute__((deprecated));

@end

NS_ASSUME_NONNULL_END
