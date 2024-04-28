#import <Foundation/Foundation.h>

@class UADSBannerAdRefreshView;

/**
 * UADSBannerAdRefreshViewDelegate is a delegate class for callbacks from Unity Ads Refresh Banner operations.
 */
@protocol UADSBannerAdRefreshViewDelegate <NSObject>

@optional
/**
 * Called when the banner is loaded and ready to be placed in the view hierarchy.
 *
 * @param bannerAdRefreshView UADSBannerAdRefreshView that is to be placed in the view hierarchy.
 */
- (void)unityAdsRefreshBannerDidLoad: (UADSBannerAdRefreshView *)bannerAdRefreshView;

/**
 * Called when the banner fails to fill.
 *
 * @param bannerAdRefreshView UADSBannerAdRefreshView that load was called on and failed to fill.
 */
- (void)unityAdsRefreshBannerDidNoFill: (UADSBannerAdRefreshView *)bannerAdRefreshView;

/**
 * Called when the banner is shown.
 *
 * @param bannerAdRefreshView UADSBannerAdRefreshView that was shown.
 */
- (void)unityAdsRefreshBannerDidShow: (UADSBannerAdRefreshView *)bannerAdRefreshView;

/**
 * Called when the banner is hidden.
 *
 * @param bannerAdRefreshView UADSBannerAdRefreshView that was hidden
 */
- (void)unityAdsRefreshBannerDidHide: (UADSBannerAdRefreshView *)bannerAdRefreshView;

/**
 * Called when the user clicks the banner.
 *
 * @param bannerAdRefreshView UADSBannerAdRefreshView that the click occurred on.
 */
- (void)unityAdsRefreshBannerDidClick: (UADSBannerAdRefreshView *)bannerAdRefreshView;

/**
 *  Called when `UnityAdsBanner` encounters an error. All errors will be logged but this method can be used as an additional debugging aid. This callback can also be used for collecting statistics from different error scenarios.
 *
 *  @param bannerAdRefreshView UADSBannerAdRefreshView that encountered an error.
 *  @param message A human readable string indicating the type of error encountered.
 */
- (void)unityAdsRefreshBannerDidError: (UADSBannerAdRefreshView *)bannerAdRefreshView message: (NSString *)message;

@end
