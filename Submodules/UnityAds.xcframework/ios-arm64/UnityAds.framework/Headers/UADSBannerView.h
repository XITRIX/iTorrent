#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UnityAds/UADSBannerViewDelegate.h>
#import <UnityAds/UADSLoadOptions.h>

NS_ASSUME_NONNULL_BEGIN

@interface UADSBannerView : UIView

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readwrite, nullable, weak) NSObject <UADSBannerViewDelegate> *delegate;
@property (nonatomic, readonly) NSString *placementId;

- (instancetype)initWithPlacementId: (NSString *)placementId size: (CGSize)size;

- (void) load;
- (void) loadWithOptions: (UADSLoadOptions *)options;

@end

NS_ASSUME_NONNULL_END
