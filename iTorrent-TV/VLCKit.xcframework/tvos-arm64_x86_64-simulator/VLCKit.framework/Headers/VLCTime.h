/*****************************************************************************
 * VLCTime.h: VLCKit.framework VLCTime header
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2007-2016 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
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

/**
 * Provides an object to define VLCMedia's time.
 */
OBJC_VISIBLE
@interface VLCTime : NSObject

/**
 * factorize an empty time object
 * \return the VLCTime object
 */
+ (VLCTime *)nullTime;
/**
 * factorize a time object with a given number object
 * \param aNumber the NSNumber object with a time in milliseconds
 * \return the VLCTime object
 */
+ (VLCTime *)timeWithNumber:(nullable NSNumber *)aNumber;
/**
 * factorize a time object with a given integer
 * \param aInt the int with a time in milliseconds
 * \return the VLCTime object
 */
+ (VLCTime *)timeWithInt:(int)aInt;
/**
 * return the libvlc clock time as microseconds
 */
+ (int64_t)clock;
/**
 * return the delay (in microseconds) until a specific timestamp
 * \param ts the target timestamp
 * \return negative if timestamp is in the past, positive if it is in the future
 */
+ (int64_t)delay:(int64_t)ts;

/**
 * init a time object with a given number object
 * \param aNumber the NSNumber object with a time in milliseconds
 * \return the VLCTime object
 */
- (instancetype)initWithNumber:(nullable NSNumber *)aNumber;
/**
 * init a time object with a given integer
 * \param aInt the int with a time in milliseconds
 * \return the VLCTime object
 */
- (instancetype)initWithInt:(int)aInt;

/* Properties */
/**
 * the current time value as NSNumber
 * \return the NSNumber object
 */
@property (nonatomic, readonly, nullable) NSNumber * value;    ///< Holds, in milliseconds, the VLCTime value

/**
 * the current time value as string value localized for the current environment
 * \return the NSString object
 */
@property (readonly) NSString * stringValue;
/**
 * the current time value as verbose localized string
 * examples: 17 minutes 1 second, 1 Stunde 33 Minuten und 41 Sekunden
 * \return the NSString object
 */
@property (readonly) NSString * verboseStringValue;
/**
 * the current time value as string value localized for the current environment representing the time in minutes
 * \return the NSString object
 */
@property (readonly) NSString * minuteStringValue;
/**
 * the current time value as int value
 * \return the int
 */
@property (readonly) int intValue;
/**
 * the current time value as string value localized for the current environment including subseconds
 * \return the NSString object
 */
@property (readonly) NSString * subSecondStringValue;

/* Comparators */
/**
 * compare the current VLCTime instance against another instance
 * \param aTime the VLCTime instance to compare against
 * \return a NSComparisonResult
 */
- (NSComparisonResult)compare:(VLCTime *)aTime;
/**
 * compare the current VLCTime instance against another instance
 * \param object the VLCTime instance to compare against
 * \return a BOOL whether the instances are equal or not
 */
- (BOOL)isEqual:(nullable id)object;
/**
 * Calculcate a unique hash for the current time instance
 * \return a hash value
 */
- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END
