
#ifndef USRVInitializeStateType_h
#define USRVInitializeStateType_h

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM (NSInteger, USRVInitializeStateType) {
    USRVInitializeStateTypeConfigLocal,
    USRVInitializeStateTypeConfigFetch,
    USRVInitializeStateTypeReset,
    USRVInitializeStateTypeInitModules,
    USRVInitializeStateTypeLoadWebView,
    USRVInitializeStateTypeCreateWebView,
    USRVInitializeStateTypeComplete
};

@protocol USRVInitializeTask <NSObject>
- (void)startWithCompletion:(void (^)(void))completion error:(void (^)(NSError *))error;
- (NSString *)systemName;
- (NSInteger)retryCount;
@end

NS_ASSUME_NONNULL_END
#endif /* USRVInitializeStateType_h */
