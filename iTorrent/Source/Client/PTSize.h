

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A class used to define the size of a torrent.
 */
@interface PTSize : NSObject

/**
 Creates and returns a `PTSize` object containing a given value, treating it as an `NSNumber`.
 */
+ (instancetype)sizeWithNumber:(NSNumber *)number;

/**
 Creates and returns a `PTSize` object containing a given value, treating it as a `long long`.
 */
+ (instancetype)sizeWithLongLong:(long long)longLong;

/**
 Creates and returns an empty size object (0 bytes).
 */
+ (instancetype)zeroSize;

/**
 Returns a `PTSize` object initialized to contain a given value, treated as an `NSNumber`.
 */
- (instancetype)initWithNumber:(NSNumber *)number;

/**
 Returns a `PTSize` object initialized to contain a given value, treated as a `long long`.
 */
- (instancetype)initWithLongLong:(long long)longLong NS_DESIGNATED_INITIALIZER;

/**
 The size expressed as a human-readable string, formatted with `NSByteCountFormatter`.
 */
@property (strong, nonatomic, readonly) NSString *stringValue;

/**
 The size expressed as a `long long`, converted as necessary.
 */
@property (nonatomic, readonly) long long longLongValue;

/**
 The size wrapped in an `NSNumber` object.
 */
@property (strong, nonatomic, readonly) NSNumber *numberValue;

/**
 Returns an `NSComparisonResult` value that indicates whether the current object’s value is greater than, equal to, or less than a given size.
 
 @param otherSize   The size to compare to the current object’s value.
 
 @return    `NSOrderedAscending` if the value of otherSize is greater than the value of the current object, `NSOrderedSame` if they’re equal, and `NSOrderedDescending` if the value of otherSize is less than that of the current object.
 */
- (NSComparisonResult)compare:(PTSize *)otherSize;

#pragma mark - Hidden methods

- (instancetype) __unavailable init;
+ (instancetype) __unavailable new;

@end

NS_ASSUME_NONNULL_END
