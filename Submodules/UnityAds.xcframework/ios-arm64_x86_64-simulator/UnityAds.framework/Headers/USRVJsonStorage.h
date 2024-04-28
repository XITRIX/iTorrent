
@protocol UADSJsonStorageContentsReader <NSObject>
- (NSDictionary *)getContents;
@end

@protocol UADSJsonStorageReader <NSObject>
- (id)            getValueForKey: (NSString *)key;
@end

@interface USRVJsonStorage : NSObject<UADSJsonStorageContentsReader, UADSJsonStorageReader>

@property (nonatomic, strong) NSMutableDictionary *storageContents;

- (BOOL)set: (NSString *)key value: (id)value;
- (id)getValueForKey: (NSString *)key;
- (BOOL)deleteKey: (NSString *)key;
- (NSArray *)getKeys: (NSString *)key recursive: (BOOL)recursive;
- (void)          clearData;
- (BOOL)          initData;
- (BOOL)          hasData;
- (void)setContents: (NSDictionary *)contents;
- (NSDictionary *)getContents;

@end
