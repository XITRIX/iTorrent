/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Describes the look and feel of a native ad view.
 */
@interface FBNativeAdViewAttributes : NSObject <NSCopying>

/**
 Initializes native ad view attributes with a dictionary
 */
- (instancetype)initWithDictionary:(NSDictionary<id, id> *)dict NS_DESIGNATED_INITIALIZER;

/**
 Background color of the native ad view.
 */
@property (nonatomic, copy, nullable) UIColor *backgroundColor;
/**
 Color of the title label.
 */
@property (nonatomic, copy, nullable) UIColor *titleColor;
/**
 Color of the advertiser name label.
 */
@property (nonatomic, copy, nullable) UIColor *advertiserNameColor;
/**
 Color of the ad choices icon.
 */
@property (nonatomic, copy, nullable) UIColor *adChoicesForegroundColor;
/**
 Font of the title label.
 */
@property (nonatomic, copy, nullable) UIFont *titleFont;
/**
 Color of the description label.
 */
@property (nonatomic, copy, nullable) UIColor *descriptionColor;
/**
 Font of the description label.
 */
@property (nonatomic, copy, nullable) UIFont *descriptionFont;
/**
 Background color of the call to action button.
 */
@property (nonatomic, copy, nullable) UIColor *buttonColor;
/**
 Color of the call to action button's title label.
 */
@property (nonatomic, copy, nullable) UIColor *buttonTitleColor;
/**
 Font of the call to action button's title label.
 */
@property (nonatomic, copy, nullable) UIFont *buttonTitleFont;
/**
 Border color of the call to action button. If nil, no border is shown.
 */
@property (nonatomic, copy, nullable) UIColor *buttonBorderColor;
/**
 Enables or disables autoplay for some types of media. Defaults to YES.
 */
@property (nonatomic, assign, getter=isAutoplayEnabled) BOOL autoplayEnabled
    __attribute((deprecated("This attribute is no longer used.")));

@end

NS_ASSUME_NONNULL_END
