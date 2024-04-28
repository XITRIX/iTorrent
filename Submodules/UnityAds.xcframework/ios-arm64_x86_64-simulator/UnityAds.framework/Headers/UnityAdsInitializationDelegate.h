#import <UnityAds/UnityAdsInitializationError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `UnityAdsInitializationDelegate` defines the methods which will notify UnityAds
 * has either successfully initialized or failed with error category and error message
 */

@protocol UnityAdsInitializationDelegate <NSObject>
/**
 * Called when `UnityAds` is successfully initialized
 */
- (void)initializationComplete;
/**
 * Called when `UnityAds` is failed in initialization.
 * @param error
 *           if `kUnityInitializationErrorInternalError`, initialization failed due to environment or internal services
 *           if `kUnityInitializationErrorInvalidArgument`, initialization failed due to invalid argument(e.g. game ID)
 *           if `kUnityInitializationErrorAdBlockerDetected`, initialization failed due to url being blocked
 * @param message A human readable error message
 */
- (void)initializationFailed: (UnityAdsInitializationError)error withMessage: (NSString *)message;

@end

NS_ASSUME_NONNULL_END
