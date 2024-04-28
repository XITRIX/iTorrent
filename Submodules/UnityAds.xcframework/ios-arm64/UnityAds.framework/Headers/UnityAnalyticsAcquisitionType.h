
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, UnityAnalyticsAcquisitionType) {
    kUnityAnalyticsAcquisitionTypeUnset,
    kUnityAnalyticsAcquisitionTypeSoft,
    kUnityAnalyticsAcquisitionTypePremium
};

NSString * NSStringFromUnityAnalyticsAcquisitionType(UnityAnalyticsAcquisitionType);

NS_ASSUME_NONNULL_END
