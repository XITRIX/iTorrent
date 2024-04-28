
NS_ASSUME_NONNULL_BEGIN

// C#
@protocol UANAEngineDelegate <NSObject>
- (void)addExtras: (NSString *)extras;
@end

// Webview
@interface UANAApiAnalytics : NSObject
+ (void)setAnalyticsDelegate: (id <UANAEngineDelegate>)analyticsDelegate;
@end

NS_ASSUME_NONNULL_END
