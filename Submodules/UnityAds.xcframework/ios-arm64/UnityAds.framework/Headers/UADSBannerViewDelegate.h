#import <Foundation/Foundation.h>
#import <UnityAds/UADSBannerError.h>

@class UADSBannerView;

/**
 * UnityAdsBannerDelegate is a delegate class for callbacks from Unity Ads Banner operations.
 */
@protocol UADSBannerViewDelegate <NSObject>

@optional
/**
 * Called when the banner is loaded and ready to be placed in the view hierarchy.
 *
 * @param bannerView View that was loaded
 */
- (void)bannerViewDidLoad: (UADSBannerView *)bannerView;

@optional
/**
 * Called when the banner is showed in the view hierarchy.
 *
 * @param bannerView View that was showed
 */
- (void)bannerViewDidShow: (UADSBannerView *)bannerView;

/**
 * Called when the user clicks the banner.
 *
 * @param bannerView View that the click occurred on.
 */
- (void)bannerViewDidClick: (UADSBannerView *)bannerView;

/**
 * Called when a banner causes
 * @param bannerView View that triggered leaving application
 */
- (void)bannerViewDidLeaveApplication: (UADSBannerView *)bannerView;

/**
 *  Called when `UnityAdsBanner` encounters an error. All errors will be logged but this method can be used as an additional debugging aid. This callback can also be used for collecting statistics from different error scenarios.
 *
 *  @param bannerView View that encountered an error.
 *  @param error UADSBannerError that occurred
 */
- (void)bannerViewDidError: (UADSBannerView *)bannerView error: (UADSBannerError *)error;

@end
