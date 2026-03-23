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

#ifndef VLCFilter_h
#define VLCFilter_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMediaPlayer;

@protocol VLCFilter;

/**
 * The protocol used to get/set a filter parameter's value, get its default value and allowed values range
 */
NS_SWIFT_NAME(VLCFilterParameterProtocol)
@protocol VLCFilterParameter <NSObject>
@property (nonatomic) id value;
@property (nonatomic, readonly) id defaultValue;
@property (nonatomic, readonly) id minValue;
@property (nonatomic, readonly) id maxValue;
- (BOOL)isValueSetToDefault;
@end

@protocol VLCFilter <NSObject>

/**
 * Reference to the media player whom this filter is applied
 */
@property (nonatomic, weak, readonly) VLCMediaPlayer *mediaPlayer;

/**
 * Enable or disable the filter
 * Default to NO
 * This value will be automatically set to YES if any of the filter parameters' value is changed
 */
@property (nonatomic, getter=isEnabled) BOOL enabled;

/**
 * A dictionay containing all filter's parameters
 */
@property (nonatomic, readonly) NSDictionary< NSString*, id<VLCFilterParameter> > *parameters;

/**
 * Reset all filter parameters to default values only if their values have been previously changed
 * Note that calling this method won't disable the filter
 * If you want to disable the filter, you must call -[VLCAdjustFilter setEnabled:NO] explicitely
 * \return YES if parameters needed a reset
 */
- (BOOL)resetParametersIfNeeded;

/**
 *  Copy all parameters' value from another filter
 * \param anotherFilter
 */
- (void)applyParametersFrom:(id<VLCFilter>)otherFilter;

@end

NS_ASSUME_NONNULL_END

#endif /* VLCFilter_h */
