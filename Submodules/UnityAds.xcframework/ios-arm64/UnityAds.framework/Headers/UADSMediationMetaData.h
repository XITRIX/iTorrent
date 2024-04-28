#import <UnityAds/UADSMetaData.h>

@interface UADSMediationMetaData : UADSMetaData

- (void)setName: (NSString *)mediationNetworkName;
- (void)setVersion: (NSString *)mediationSdkVersion;
- (void)setOrdinal: (int)mediationOrdinal;
- (void)setMissedImpressionOrdinal: (int)missedImpressionOrdinal;

@end
