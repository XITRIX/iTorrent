/*****************************************************************************
 * VLCKit.h: VLCKit.framework main header
 *****************************************************************************
 * Copyright (C) 2007-2010 Pierre d'Herbemont
 * Copyright (C) 2007, 2013-2025 VLC authors and VideoLAN
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org
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

#include <TargetConditionals.h>

#import <VLCKit/VLCAudio.h>
#import <VLCKit/VLCLibrary.h>
#import <VLCKit/VLCMedia.h>
#import <VLCKit/VLCMediaDiscoverer.h>
#import <VLCKit/VLCMediaList.h>
#import <VLCKit/VLCMediaPlayer.h>
#import <VLCKit/VLCAudioEqualizer.h>
#import <VLCKit/VLCMediaListPlayer.h>
#import <VLCKit/VLCMediaThumbnailer.h>
#import <VLCKit/VLCMediaMetaData.h>
#import <VLCKit/VLCTime.h>
#import <VLCKit/VLCFilter.h>
#import <VLCKit/VLCAdjustFilter.h>
#import <VLCKit/VLCLogging.h>
#import <VLCKit/VLCConsoleLogger.h>
#import <VLCKit/VLCFileLogger.h>
#import <VLCKit/VLCLogMessageFormatter.h>
#import <VLCKit/VLCEventsConfiguration.h>
#import <VLCKit/VLCMediaPlayerTitleDescription.h>
#if !TARGET_OS_WATCH
#import <VLCKit/VLCDrawable.h>
#import <VLCKit/VLCDialogProvider.h>
#endif

#if TARGET_OS_OSX
#import <VLCKit/VLCTranscoder.h>
#import <VLCKit/VLCStreamOutput.h>
#import <VLCKit/VLCStreamSession.h>
#import <VLCKit/VLCVideoLayer.h>
#import <VLCKit/VLCVideoView.h>
#import <VLCKit/VLCRendererDiscoverer.h>
#import <VLCKit/VLCRendererItem.h>
#endif
#if TARGET_OS_IOS
#import <VLCKit/VLCTranscoder.h>
#import <VLCKit/VLCRendererDiscoverer.h>
#import <VLCKit/VLCRendererItem.h>
#endif

@class VLCMedia;
@class VLCMediaList;
@class VLCTime;
@class VLCAudio;
@class VLCMediaThumbnailer;
@class VLCMediaListPlayer;
@class VLCMediaPlayer;
@class VLCAudioEqualizer;
@class VLCAudioEqualizerPreset;
@class VLCAudioEqualizerBand;
#if !TARGET_OS_WATCH
@class VLCDialogProvider;
#endif
@class VLCRendererDiscoverer;
@class VLCRendererDiscovererDescription;
@class VLCRendererItem;
@class VLCFilterParameter;
@class VLCAdjustFilter;
@class VLCMediaMetaData;
@class VLCConsoleLogger;
@class VLCFileLogger;
@class VLCLogMessageFormatter;
@class VLCMediaPlayerChapterDescription;
@class VLCMediaPlayerTitleDescription;

#if TARGET_OS_IPHONE
@class VLCAudio;
@class VLCMediaListPlayer;
@class VLCMediaPlayer;
@class VLCMediaThumbnailer;
@class VLCRendererDiscoverer;
@class VLCRendererDiscovererDescription;
@class VLCRendererItem;
#else
@class VLCVideoView;
#endif
