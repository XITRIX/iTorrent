/**
 *  An enumeration for the show completion state of an ad.
 */
typedef NS_ENUM (NSInteger, UnityAdsShowCompletionState) {
    /**
     *  A state that indicates that the user skipped the ad.
     */
    kUnityShowCompletionStateSkipped,
    /**
     *  A state that indicates that the ad was played entirely.
     */
    kUnityShowCompletionStateCompleted
};
