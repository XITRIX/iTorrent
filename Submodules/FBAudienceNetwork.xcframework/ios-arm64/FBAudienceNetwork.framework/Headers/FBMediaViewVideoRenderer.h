/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The FBMediaViewVideoRenderer class allows for customization of the user experience for video ads in FBMediaView. This
 class should be subclassed, and an instance of that subclass should be passed to the videoRenderer property of an
 FBMediaView instance.
 */
FB_CLASS_EXPORT
@interface FBMediaViewVideoRenderer : UIView

/**
 The aspect ratio of the video content. Returns a positive CGFloat, or 0.0 if no ad is currently loaded.
 */
@property (nonatomic, assign, readonly) CGFloat aspectRatio;

/**
 The current video playback time, as a CMTime value.
 */
@property (nonatomic, assign, readonly) CMTime currentTime;

/**
 The duration of the video, as a CMTime value.  Returns kCMTimeIndefinite if no video is loaded.
 */
@property (nonatomic, assign, readonly) CMTime duration;

/**
 Indicates whether the video is currently playing.
 */
@property (nonatomic, assign, readonly, getter=isPlaying) BOOL playing;

/**
 The current volume of the video, ranging from 0.0 through 1.0.
 */
@property (nonatomic, assign) float volume;

/**
 Starts or resumes video playback.
 */
- (void)playVideo;

/**
 Pauses video playback.
 */
- (void)pauseVideo;

/**
 Used to put the video into seek mode.  Video playback halts, and one or more calls to seekVideoToTime: can be made
 before calling disengageVideoSeek.
 */
- (void)engageVideoSeek;

/**
 Take the video out of seek mode.
 */
- (void)disengageVideoSeek;

/**
 Seeks the video to a particular time location.  Only works after calling `engageVideoSeek`.
 @param time The requested time location, expressed as a CMTime value.
 */
- (void)seekVideoToTime:(CMTime)time;

/**
 Requests the periodic invocation of a given block during playback to report changing time.
 @param interval The time interval at which the block should be invoked during normal playback, according to progress of
 the player's current time.
 @param queue A serial dispatch queue onto which block should be enqueued.
 @param block The block to be invoked periodically.
 */
- (nullable id)addPeriodicTimeObserverForInterval:(CMTime)interval
                                            queue:(dispatch_queue_t)queue
                                       usingBlock:(void (^)(CMTime time))block;

/**
 Cancels a previously registered periodic time observer.
 */
- (void)removeTimeObserver:(id)observer;

/**
 Called when the video volume has changed.
 */
- (void)videoDidChangeVolume;

/**
 Called when video content has loaded.
 */
- (void)videoDidLoad;

/**
 Called when video playback was paused.
 */
- (void)videoDidPause;

/**
 Called when video playback has begun or was resumed.
 */
- (void)videoDidPlay;

/**
 Called when seek mode was engaged.
 */
- (void)videoDidEngageSeek;

/**
 Called when a video seek was performed.
 */
- (void)videoDidSeek;

/**
 Called when seek mode was disengaged.
 */
- (void)videoDidDisengageSeek;

/**
 Called when video playback ends.
 */
- (void)videoDidEnd;

/**
 Called when video playback encounters an error.
 */
- (void)videoDidFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
