/*****************************************************************************
 * VLCConsoleLogger.h: [Mobile/TV]VLCKit.framework VLCConsoleLogger header
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
 * \brief A simple console logger to be used with a library instance
 * \see -[VLCLibrary loggers]
 */
@interface VLCConsoleLogger : NSObject<VLCFormattedMessageLogging>

/**
 * \brief Used to format handled log infos
 * \note Set to an instance of `VLCLogMessageFormatter` by default
 * \warning Won't accept nil value
 * \see VLCLogMessageFormatting
 */
@property (nonatomic, readwrite) id<VLCLogMessageFormatting> formatter;

@end

NS_ASSUME_NONNULL_END
