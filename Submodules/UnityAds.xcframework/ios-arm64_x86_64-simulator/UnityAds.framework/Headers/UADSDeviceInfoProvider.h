#import <Foundation/Foundation.h>

@protocol UADSDeviceInfoProvider
- (NSDictionary*)getDeviceInfoWithExtended:(BOOL)extended;
@end
