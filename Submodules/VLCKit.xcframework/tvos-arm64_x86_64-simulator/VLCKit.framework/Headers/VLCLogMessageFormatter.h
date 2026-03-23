/*****************************************************************************
 * VLCLogMessageFormatter.h: [Mobile/TV]VLCKit.framework VLCLogMessageFormatter header
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
 * \brief A simple log message formatter
 * \discussion This formatter will format a message like "[level] message context"
 * \warning Any customContext object not responding to the `description` message will be ignored
 */
@interface VLCLogMessageFormatter : NSObject<VLCLogMessageFormatting>

@end

NS_ASSUME_NONNULL_END
