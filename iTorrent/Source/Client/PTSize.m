

#import "PTSize.h"

@implementation PTSize {
    long long byteCount;
}


- (instancetype)initWithNumber:(NSNumber *)number {
    return [self initWithLongLong:number.longLongValue];
}

+ (instancetype)sizeWithNumber:(NSNumber *)number {
  return [[PTSize alloc] initWithNumber:number];
}

+ (instancetype)sizeWithLongLong:(long long)longLong {
    return [[PTSize alloc] initWithLongLong:longLong];
}

+ (instancetype)zeroSize {
    return [[PTSize alloc] initWithLongLong:0];
}

- (instancetype)initWithLongLong:(long long)longLong {
    self = [super init];
    
    if (self) {
        byteCount = longLong;
    }
    
    return self;
}

- (NSNumber *)numberValue {
    return [NSNumber numberWithLongLong:byteCount];
}

- (long long)longLongValue {
    return byteCount;
}


- (NSString *)stringValue {
    return [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
}


- (NSComparisonResult)compare:(PTSize *)otherSize {
    return [self.numberValue compare:otherSize.numberValue];
}



@end
