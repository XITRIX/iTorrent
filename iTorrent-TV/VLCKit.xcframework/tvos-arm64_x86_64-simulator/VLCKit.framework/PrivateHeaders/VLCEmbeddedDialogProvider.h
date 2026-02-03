/*****************************************************************************
 * VLCEmbeddedDialogProvider.h: an implementation of the libvlc dialog API
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

#import <VLCDialogProvider.h>

@interface VLCEmbeddedDialogProvider : VLCDialogProvider

/**
 * initializer method to run the dialog provider instance on a specific library instance
 *
 * \param library instance
 * \note if param is NULL, [VLCLibrary sharedLibrary] will be used
 * \return the dialog provider instance, can be NULL on malloc failures
 */
- (instancetype _Nullable)initWithLibrary:(VLCLibrary * _Nullable)library;

@end
