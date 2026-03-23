/*****************************************************************************
 * VLCMediaMetaData.h: VLCKit.framework VLCMediaMetaData header
 *****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
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
#if TARGET_OS_IPHONE
#import <UIKit/UIImage.h>
#else
#import <AppKit/NSImage.h>
#endif

/**
 * UIImage or NSImage
 */
typedef
#if TARGET_OS_IPHONE
UIImage
#else
NSImage
#endif
VLCPlatformImage;

NS_ASSUME_NONNULL_BEGIN

/**
 * VLCMediaMetaData
 */
NS_SWIFT_NAME(VLCMedia.MetaData)
@interface VLCMediaMetaData : NSObject

/**
 * meta title
 */
@property(nonatomic, copy, nullable) NSString *title;

/**
 * meta artist
 */
@property(nonatomic, copy, nullable) NSString *artist;

/**
 * meta genre
 */
@property(nonatomic, copy, nullable) NSString *genre;

/**
 * meta copyright
 */
@property(nonatomic, copy, nullable) NSString *copyright;

/**
 * meta album
 */
@property(nonatomic, copy, nullable) NSString *album;

/**
 * meta track number
 */
@property(nonatomic) unsigned trackNumber;

/**
 * meta description
 */
@property(nonatomic, copy, nullable) NSString *metaDescription;

/**
 * meta rating
 */
@property(nonatomic, copy, nullable) NSString *rating;

/**
 * meta date
 */
@property(nonatomic, copy, nullable) NSString *date;

/**
 * meta setting
 */
@property(nonatomic, copy, nullable) NSString *setting;

/**
 * meta url
 */
@property(nonatomic, nullable) NSURL *url;

/**
 * meta language
 */
@property(nonatomic, copy, nullable) NSString *language;

/**
 * meta now playing
 */
@property(nonatomic, copy, nullable) NSString *nowPlaying;

/**
 * meta publisher
 */
@property(nonatomic, copy, nullable) NSString *publisher;

/**
 * meta encoded by
 */
@property(nonatomic, copy, nullable) NSString *encodedBy;

/**
 * meta artwork URL
 */
@property(nonatomic, nullable) NSURL *artworkURL;

/**
 * meta track ID
 */
@property(nonatomic) unsigned trackID;

/**
 * meta track total
 */
@property(nonatomic) unsigned trackTotal;

/**
 * meta director
 */
@property(nonatomic, copy, nullable) NSString *director;

/**
 * meta season
 */
@property(nonatomic) unsigned season;

/**
 * meta episode
 */
@property(nonatomic) unsigned episode;

/**
 * meta show name
 */
@property(nonatomic, copy, nullable) NSString *showName;

/**
 * meta actors
 */
@property(nonatomic, copy, nullable) NSString *actors;

/**
 * meta album artist
 */
@property(nonatomic, copy, nullable) NSString *albumArtist;

/**
 * meta disc number
 */
@property(nonatomic) unsigned discNumber;

/**
 * meta disc total
 */
@property(nonatomic) unsigned discTotal;

/**
 * artwork
 */
@property(nonatomic, readonly, nullable) VLCPlatformImage *artwork;

/**
 * extra
 */
@property(nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSString *> *extra;


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * Save the previously changed metadata
 * \return true if saving was successful
 */
- (BOOL)save;

/**
 * Note, you need to call libvlc_media_parse_with_options() or play the media at least once before calling this function.
 */
- (void)prefetch;


- (void)clearCache;

/**
 * Read the meta extra of the media.
 */
- (nullable NSString *)extraValueForKey:(NSString *)key;

/**
 * Set the meta of the media
 */
- (void)setExtraValue:(nullable NSString *)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
