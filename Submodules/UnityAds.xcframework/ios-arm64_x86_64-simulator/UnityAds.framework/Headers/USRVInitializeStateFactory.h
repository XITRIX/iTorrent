#import <Foundation/Foundation.h>
#import <UnityAds/USRVInitializeStateType.h>

NS_ASSUME_NONNULL_BEGIN


@interface USRVInitializeStateFactory : NSObject

+(instancetype)newWithBuilder: (id)configurationLoader
              andConfigReader: (_Nullable id)configReader; // erasing type at this point to be able to connect with swift. Nullable config reader is done to ease integration tests for SDKinit on swift side
-(id<USRVInitializeTask>)stateFor: (USRVInitializeStateType)type;
@end

NS_ASSUME_NONNULL_END
