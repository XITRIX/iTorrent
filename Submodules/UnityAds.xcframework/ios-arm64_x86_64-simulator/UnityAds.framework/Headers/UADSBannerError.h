#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, UADSBannerErrorCode) {
    UADSBannerErrorCodeUnknown      = 0,
    UADSBannerErrorCodeNativeError  = 1,
    UADSBannerErrorCodeWebViewError = 2,
    UADSBannerErrorCodeNoFillError  = 3,
    UADSBannerErrorInitializeFailed = 4,
    UADSBannerErrorInvalidArgument = 5
};

@interface UADSBannerError : NSError

- (instancetype)initWithCode: (UADSBannerErrorCode)code userInfo: (nullable NSDictionary<NSErrorUserInfoKey, id> *)dict;

@end

NS_ASSUME_NONNULL_END
