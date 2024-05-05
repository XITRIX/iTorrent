/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents an image creative.
 */
FB_CLASS_EXPORT
@interface FBAdImage : NSObject

/**
 Typed access to the image url.
 */
@property (nonatomic, copy, readonly) NSURL *url;
/**
 Typed access to the image width.
 */
@property (nonatomic, assign, readonly) NSInteger width;
/**
 Typed access to the image height.
 */
@property (nonatomic, assign, readonly) NSInteger height;

/**
 Initializes FBAdImage instance with given parameters.

 @param url the image url.
 @param width the image width.
 @param height the image height.
 */
- (instancetype)initWithURL:(NSURL *)url width:(NSInteger)width height:(NSInteger)height NS_DESIGNATED_INITIALIZER;

/**
 Loads an image from self.url over the network, or returns the cached image immediately.

 @param block Block that is calledn upon completion of image loading
 */
- (void)loadImageAsyncWithBlock:(nullable void (^)(UIImage *__nullable image))block;

@end

NS_ASSUME_NONNULL_END
