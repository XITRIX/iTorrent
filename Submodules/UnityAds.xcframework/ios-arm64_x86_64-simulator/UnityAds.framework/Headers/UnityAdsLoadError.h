#import <Foundation/Foundation.h>
/**
 *  An enumeration for the error category of load errors
 */
typedef NS_ENUM (NSInteger, UnityAdsLoadError) {
    /**
     * Error related to SDK not initialized
     */
    kUnityAdsLoadErrorInitializeFailed,

    /**
     * Error related to environment or internal services
     */
    kUnityAdsLoadErrorInternal,

    /**
     * Error related to invalid arguments
     */
    kUnityAdsLoadErrorInvalidArgument,

    /**
     * Error related to there being no ads available
     */
    kUnityAdsLoadErrorNoFill,

    /**
     * Error related to there being no ads available
     */
    kUnityAdsLoadErrorTimeout,
};
