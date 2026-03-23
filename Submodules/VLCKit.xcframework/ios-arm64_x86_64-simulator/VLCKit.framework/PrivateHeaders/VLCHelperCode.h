/*****************************************************************************
 * VLCHelperCode.h: generic helper code
 *****************************************************************************
 * Copyright (C) 2016 VideoLabs SAS
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
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

NSString *toNSStr(const char *str);

#ifndef NDEBUG
#    define VKLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#    define VKLog(format, ...)
#endif

#ifndef N_
#    define N_(str) gettext_noop(str)
#    define gettext_noop(str) (str)
#endif

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#    define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
#else
#    define NS_DESIGNATED_INITIALIZER
#endif
#endif
