/*****************************************************************************
 * VLCAudioEqualizer.h: VLCKit.framework VLCAudioEqualizer header
 *****************************************************************************
 * Copyright (C) 2023 VLC authors and VideoLAN
 * $Id$
 *
 * Authors:
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// VLCAudioEqualizerPreset
NS_SWIFT_NAME(VLCAudioEqualizer.Preset)
@interface VLCAudioEqualizerPreset : NSObject

/// equalizer preset name
@property (nonatomic, copy, readonly) NSString *name;
/// equalizer preset index
@property (nonatomic, readonly) unsigned index;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

/// VLCAudioEqualizerBand
NS_SWIFT_NAME(VLCAudioEqualizer.Band)
@interface VLCAudioEqualizerBand : NSObject

/// frequency
///
/// equalizer band frequency (Hz), or -1 if there is no such band
@property (nonatomic, readonly) float frequency;

/// index
///
/// index, counting from zero, of the frequency band to set
@property (nonatomic, readonly) unsigned index;

/// amplification
///
/// amplification value (-20.0 to 20.0 Hz)
@property (nonatomic) float amplification;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

/// VLCAudioEqualizer
NS_SWIFT_NAME(VLCAudioEqualizer)
@interface VLCAudioEqualizer : NSObject

/// equalizer presets
@property (class, nonatomic, copy, readonly) NSArray<VLCAudioEqualizerPreset *> *presets;

/// preAmplification
///
/// preamp value (-20.0 to 20.0 Hz)
@property (nonatomic) float preAmplification;

/// equalizer bands
@property (nonatomic, copy, readonly) NSArray<VLCAudioEqualizerBand *> *bands;

- (instancetype)init;
- (instancetype)initWithPreset:(VLCAudioEqualizerPreset *)preset;

@end

NS_ASSUME_NONNULL_END
