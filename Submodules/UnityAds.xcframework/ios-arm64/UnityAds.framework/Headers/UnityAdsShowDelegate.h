#import <UnityAds/UnityAdsShowError.h>
#import <UnityAds/UnityAdsShowCompletionState.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `UnityAdsShowDelegate` defines the methods which will notify UnityAds show call
 * is either successfully completed with its completion state or failed with error category and error message
 */

@protocol UnityAdsShowDelegate <NSObject>
/**
 * Called when UnityAds completes show operation successfully for a placement with completion state.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 * @param state An enum value indicating the finish state of the ad. Possible values are `Completed`, `Skipped`.
 */
- (void)unityAdsShowComplete: (NSString *)placementId withFinishState: (UnityAdsShowCompletionState)state;
/**
 * Called when UnityAds has failed to show a specific placement with an error message and error category.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 * @param error
 *           if `kUnityShowErrorNotInitialized`, show failed due to SDK not initialized.
 *           if `kUnityShowErrorNotReady`, show failed due to placement  not being ready.
 *           if `kUnityShowErrorVideoPlayerError`, show failed due to video player.
 *           if `kUnityShowErrorInvalidArgument`, show failed due to invalid arguments.
 *           if `kUnityShowErrorNoConnection`, show failed due to internet connection.
 *           if `kUnityShowErrorAlreadyShowing`, show failed due to ad is already being showen.
 *           if `kUnityShowErrorInternalError`, show failed due to environment or internal services.
 * @param message A human readable error message
 */
- (void)unityAdsShowFailed: (NSString *)placementId withError: (UnityAdsShowError)error withMessage: (NSString *)message;
/**
 * Called when UnityAds has started to show ad with a specific placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsShowStart: (NSString *)placementId;
/**
 * Called when UnityAds has received a click while showing ad with a specific placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsShowClick: (NSString *)placementId;

@end

NS_ASSUME_NONNULL_END
