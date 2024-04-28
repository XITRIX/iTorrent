#import <Foundation/Foundation.h>
/**
 *  An enumeration for the error category of show errors
 */

typedef NS_ENUM (NSInteger, UnityAdsShowError) {
    /**
     * Error related to SDK not initialized
     */
    kUnityShowErrorNotInitialized,

    /**
     * Error related to placement not being ready
     */
    kUnityShowErrorNotReady,

    /**
     * Error related to video player
     */
    kUnityShowErrorVideoPlayerError,

    /**
     * Error related to invalid arguments
     */
    kUnityShowErrorInvalidArgument,

    /**
     * Error related to internet connection
     */
    kUnityShowErrorNoConnection,

    /**
     * Error related to ad is already being shown
     */
    kUnityShowErrorAlreadyShowing,

    /**
     * Error related to environment or internal services
     */
    kUnityShowErrorInternalError,

    /**
     * Error related to an Ad being unable to show within a specified time frame
     */
    kUnityShowErrorTimeout
};
