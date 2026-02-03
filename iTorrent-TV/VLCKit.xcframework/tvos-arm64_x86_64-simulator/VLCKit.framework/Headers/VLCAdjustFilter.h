/*****************************************************************************
 * VLCFilter.h: VLCKit.framework VLCFilter header
 *****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Maxime Chapelet <umxprime # videolabs.io>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#ifndef VLCAdjustFilter_h
#define VLCAdjustFilter_h

#import "VLCFilter.h"

@class VLCMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kVLCAdjustFilterContrastParameterKey;
extern NSString * const kVLCAdjustFilterBrightnessParameterKey;
extern NSString * const kVLCAdjustFilterHueParameterKey;
extern NSString * const kVLCAdjustFilterSaturationParameterKey;
extern NSString * const kVLCAdjustFilterGammaParameterKey;

/**
 * An object to control an Adjust video filter
 * \see -[VLCMediaPlayer adjustFilter]
 */
@interface VLCAdjustFilter : NSObject<VLCFilter>

/// Convenient accessor to the contrast parameter
@property (nonatomic, readonly) id<VLCFilterParameter> contrast;

/// Convenient accessor to the brightness parameter
@property (nonatomic, readonly) id<VLCFilterParameter> brightness;

/// Convenient accessor to the hue parameter
@property (nonatomic, readonly) id<VLCFilterParameter> hue;

/// Convenient accessor to the saturation parameter
@property (nonatomic, readonly) id<VLCFilterParameter> saturation;

/// Convenient accessor to the gamma parameter
@property (nonatomic, readonly) id<VLCFilterParameter> gamma;

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)createWithVLCMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVLCMediaPlayer:(VLCMediaPlayer *)mediaPlayer NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif /* VLCAdjustFilter_h */
