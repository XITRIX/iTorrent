#import "UADSLoadOptions.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UADSBannerLoadOptions : UADSLoadOptions
@property (nonatomic, assign) CGSize size;

+(instancetype)newBannerLoadOptionsWith:(UADSLoadOptions *)loadOptions size:(CGSize)size;
@end

NS_ASSUME_NONNULL_END
