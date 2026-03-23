/*****************************************************************************
 * VLCFileLogger.h: [Mobile/TV]VLCKit.framework VLCFileLogger header
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

#import <Foundation/Foundation.h>

#import "VLCLogging.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * \brief A simple file logger to be used with a library instance
 * \see -[VLCLibrary loggers]
 */
@interface VLCFileLogger : NSObject<VLCFormattedMessageLogging>

/**
 * \brief The file handle used to write or update the log file
 */
@property (nonatomic, readonly) NSFileHandle *fileHandle;

/**
 * \brief Formatter used
 * \note Set to an instance of `VLCLogMessageFormatter` by default
 * \warning Won't accept nil value
 * \see VLCLogMessageFormatting
 */
@property (nonatomic, readwrite) id<VLCLogMessageFormatting> formatter;

+ (instancetype)new NS_UNAVAILABLE;

/**
 * \brief Class default initializer
 * \param fileHandle The file handle that was created for write or update access
 * \note The writing will silently fail if the file handle wasn't opened for write or update access
 */
+ (instancetype)createWithFileHandle:(NSFileHandle *)fileHandle;

- (instancetype)init NS_UNAVAILABLE;

/**
 * \brief Default initializer
 * \param fileHandle The file handle that was created for write or update access
 * \note The writing will silently fail if the file handle wasn't opened for write or update access
 */
- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
