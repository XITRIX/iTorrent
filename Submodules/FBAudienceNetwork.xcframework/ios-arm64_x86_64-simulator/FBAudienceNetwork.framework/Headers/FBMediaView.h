/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBMediaViewVideoRenderer.h>
#import <FBAudienceNetwork/UIView+FBNativeAdViewTag.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBMediaViewDelegate;
@class FBNativeAd;

/**
 The FBMediaView loads media content from a given FBNativeAd. This view takes the place of manually loading a cover
 image.
 */
FB_CLASS_EXPORT
@interface FBMediaView : UIView

/**
 the delegate
 */
@property (nonatomic, weak, nullable) id<FBMediaViewDelegate> delegate;

/**
 A custom FBMediaViewVideoRenderer instance, used to override the default user experience of video ads.
 The video renderer can only be set prior to registering the mediaView to a nativeAd
 */
@property (nonatomic, strong) FBMediaViewVideoRenderer *videoRenderer;

/**
 The current volume of the media view, ranging from 0.0 through 1.0.
 */
@property (nonatomic, assign, readonly) float volume;

/**
 Shows if the video will autoplay or not
 */
@property (nonatomic, readonly, getter=isAutoplayEnabled) BOOL autoplayEnabled;

/**
 The aspect ratio of the media view visual content. Returns a positive CGFloat, or 0.0 if no ad is currently loaded.
 */
@property (nonatomic, assign, readonly) CGFloat aspectRatio;

/**
 The tag for media view. It always returns FBNativeAdViewTagMedia.
 */
@property (nonatomic, assign, readonly) FBNativeAdViewTag nativeAdViewTag;

/**
 Changes the width of the FBMediaView's frame based on the current height, respecting aspectRatio.
 */
- (void)applyNaturalWidth;

/**
 Changes the height of the FBMediaView's frame based on the current width, respecting aspectRatio.
 */
- (void)applyNaturalHeight;

@end

/**
 The methods declared by the FBMediaViewDelegate protocol allow the adopting delegate to respond to messages from the
 FBMediaView class and thus respond to operations such as whether the media content has been loaded.
 */
@protocol FBMediaViewDelegate <NSObject>

@optional

/**
 Sent when a FBMediaView has been successfully loaded.


 @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewDidLoad:(FBMediaView *)mediaView;

/**
 Sent just before a FBMediaView will enter the fullscreen layout.


 @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewWillEnterFullscreen:(FBMediaView *)mediaView;

/**
 Sent after a FBMediaView has exited the fullscreen layout.


 @param mediaView An FBMediaView object sending the message.
 */
- (void)mediaViewDidExitFullscreen:(FBMediaView *)mediaView;

/**
 Sent when a FBMediaView has changed the playback volume of a video ad.


 @param mediaView A FBMediaView object sending the message.
 @param volume The current ad video volume (after the volume change).
 */
- (void)mediaView:(FBMediaView *)mediaView videoVolumeDidChange:(float)volume;

/**
 Sent after a video ad in a FBMediaView enters a paused state.


 @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewVideoDidPause:(FBMediaView *)mediaView;

/**
 Sent after a video ad in FBMediaView enters a playing state.


 @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewVideoDidPlay:(FBMediaView *)mediaView;

/**
 Sent when a video ad in a FBMediaView reaches the end of playback.


 @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewVideoDidComplete:(FBMediaView *)mediaView;

@end

NS_ASSUME_NONNULL_END
