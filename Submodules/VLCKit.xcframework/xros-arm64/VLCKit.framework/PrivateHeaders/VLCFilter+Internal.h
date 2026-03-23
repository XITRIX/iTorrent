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

#ifndef VLCFilter_Internal_h
#define VLCFilter_Internal_h

/**
 * Block type used by parameter property kVLCFilterParameterPropertyValueChangeActionKey
 */
typedef void(^VLCFilterParameterValueChangeAction)(id);

/// Internal libvlc filter option index
extern NSString * const kVLCFilterParameterPropertyLibVLCFilterOptionKey;
/// Parameter's key in filter parameters collection
extern NSString * const kVLCFilterParameterPropertyParameterKey;
/// Parameter's default value
extern NSString * const kVLCFilterParameterPropertyValueKey;
/// Parameter's default value
extern NSString * const kVLCFilterParameterPropertyDefaultValueKey;
/// Parameter's min value
extern NSString * const kVLCFilterParameterPropertyMinValueKey;
/// Parameter's max value
extern NSString * const kVLCFilterParameterPropertyMaxValueKey;
/// Parameter's change action block of type VLCFilterParameterValueChangeAction
extern NSString * const kVLCFilterParameterPropertyValueChangeActionKey;

/**
 * An object to control a filter parameter's value, get its default value and allowed values range
 */
@interface VLCFilterParameter : NSObject<VLCFilterParameter>
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)createWithProperties:(NSDictionary< NSString*,id > *)properties;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProperties:(NSDictionary< NSString*,id > *)properties NS_DESIGNATED_INITIALIZER;
@end

#endif /* VLCFilter_Internal_h */
