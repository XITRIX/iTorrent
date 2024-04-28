#import <UIKit/UIKit.h>

#import <UnityAds/UnityServices.h>
#import <UnityAds/UnityAdsInitializationDelegate.h>
#import <UnityAds/UnityAdsLoadDelegate.h>
#import <UnityAds/UnityAdsShowDelegate.h>
#import <UnityAds/UADSLoadOptions.h>
#import <UnityAds/UADSShowOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * `UnityAds` is a static class with methods for preparing and showing ads.
 */

@interface UnityAds : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)initialize NS_UNAVAILABLE;


/**
 *  Initializes UnityAds. UnityAds should be initialized when app starts.
 *
 *  @param gameId   Unique identifier for a game, given by Unity Ads admin tools or Unity editor.
 */
+ (void)initialize: (NSString *)gameId;

/**
 *  Initializes UnityAds. UnityAds should be initialized when app starts.
 *
 *  @param gameId   Unique identifier for a game, given by Unity Ads admin tools or Unity editor.
 *  @param initializationDelegate delegate for UnityAdsInitialization
 */
+ (void)        initialize: (NSString *)gameId
    initializationDelegate: (nullable id<UnityAdsInitializationDelegate>)initializationDelegate;

/**
 *  Initializes UnityAds. UnityAds should be initialized when app starts.
 *
 *  @param gameId        Unique identifier for a game, given by Unity Ads admin tools or Unity editor.
 *  @param testMode      Set this flag to `YES` to indicate test mode and show only test ads.
 */
+ (void)initialize: (NSString *)gameId
          testMode: (BOOL)testMode;

/**
 * Initializes UnityAds. UnityAds should be initialized when app starts.
 *
 *  @param gameId        Unique identifier for a game, given by Unity Ads admin tools or Unity editor.
 *  @param testMode      Set this flag to `YES` to indicate test mode and show only test ads.
 *  @param initializationDelegate delegate for UnityAdsInitialization
 */
+ (void)        initialize: (NSString *)gameId
                  testMode: (BOOL)testMode
    initializationDelegate: (nullable id<UnityAdsInitializationDelegate>)initializationDelegate;
/**
 *  Load a placement to make it available to show. Ads generally take a few seconds to finish loading before they can be shown.
 *  Note: The `load` API is in closed beta and available upon invite only. If you would like to be considered for the beta, please contact Unity Ads Support.
 *
 *  @param placementId The placement ID, as defined in Unity Ads admin tools.
 */
+ (void)load: (NSString *)placementId;

/**
 *  Load a placement to make it available to show. Ads generally take a few seconds to finish loading before they can be shown.
 *
 *  @param placementId The placement ID, as defined in Unity Ads admin tools.
 *  @param loadDelegate The load delegate.
 */
+ (void)    load: (NSString *)placementId
    loadDelegate: (nullable id<UnityAdsLoadDelegate>)loadDelegate;

/**
 *  Load a placement to make it available to show. Ads generally take a few seconds to finish loading before they can be shown.
 *
 *  @param placementId The placement ID, as defined in Unity Ads admin tools.
 *  @param options The load options.
 *  @param loadDelegate The load delegate.
 */
+ (void)    load: (NSString *)placementId
         options: (UADSLoadOptions *)options
    loadDelegate: (nullable id<UnityAdsLoadDelegate>)loadDelegate;

/**
 *  Show an ad using the provided placement ID.
 *
 *  @param viewController The `UIViewController` that is to present the ad view controller.
 *  @param placementId    The placement ID, as defined in Unity Ads admin tools.
 *  @param showDelegate The show delegate.
 */
+ (void)    show: (UIViewController *)viewController
     placementId: (NSString *)placementId
    showDelegate: (nullable id<UnityAdsShowDelegate>)showDelegate;

/**
 *  Show an ad using the provided placement ID.
 *
 *  @param viewController The `UIViewController` that is to present the ad view controller.
 *  @param placementId    The placement ID, as defined in Unity Ads admin tools.
 *  @param options    Additional options
 *  @param showDelegate The show delegate.
 */
+ (void)    show: (UIViewController *)viewController
     placementId: (NSString *)placementId
         options: (UADSShowOptions *)options
    showDelegate: (nullable id<UnityAdsShowDelegate>)showDelegate;


+ (BOOL)                getDebugMode;
/**
 *  Set the logging verbosity of `UnityAds`. Debug mode indicates verbose logging.
 *  @warning Does not relate to test mode for ad content.
 *  @param enableDebugMode `YES` for verbose logging.
 */
+ (void)setDebugMode: (BOOL)enableDebugMode;
/**
 *  Check to see if the current device supports using Unity Ads.
 *
 *  @return If `NO`, the current device cannot initialize `UnityAds` or show ads.
 */
+ (BOOL)                isSupported;
/**
 *  Check the version of this `UnityAds` SDK
 *
 *  @return String representing the current version name.
 */
+ (NSString *)          getVersion;
/**
 *  Check that `UnityAds` has been initialized. This might be useful for debugging initialization problems.
 *
 *  @return If `YES`, Unity Ads has been successfully initialized.
 */
+ (BOOL)                isInitialized;
/**
 * Get request token.
 *
 * @return Active token or null if no active token is available.
 */
+ (NSString *__nullable)getToken;

/**
 * Get request token.
 *
 * @param completion Active token or null if no active token is available.
 */
+ (void)getToken: (void (^)(NSString *_Nullable))completion;
@end

NS_ASSUME_NONNULL_END
