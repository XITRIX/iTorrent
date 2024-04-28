/**
 *  An enumeration for the error category of initialization errors
 */
typedef NS_ENUM (NSInteger, UnityAdsInitializationError) {
    /**
     *  Error related to environment or internal services.
     */
    kUnityInitializationErrorInternalError,

    /**
     * Error related to invalid arguments
     */
    kUnityInitializationErrorInvalidArgument,

    /**
     * Error related to url being blocked
     */
    kUnityInitializationErrorAdBlockerDetected
};
