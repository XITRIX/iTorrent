/*****************************************************************************
 * VLCRendererItem.h
 *****************************************************************************
 * Copyright © 2018 VLC authors, VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee<bubu@mikan.io>
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

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, VLCRendererPlay) {
    /** The renderer can render audio */
    VLCRendererPlaysAudio = 1 << 0,
    /** The renderer can render video */
    VLCRendererPlaysVideo = 1 << 1
};

/**
 * Renderer Item
 */
OBJC_VISIBLE
@interface VLCRendererItem : NSObject

/**
 * Name of the renderer item
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 * For now, the type can only be "chromecast" ("upnp", "airplay" may come later)
 */
@property (nonatomic, readonly, copy) NSString *type;

/**
 * IconURI of the renderer item
 */
@property (nonatomic, readonly, copy) NSString *iconURI;

/**
 * Flags of the renderer item
 */
@property (nonatomic, readonly, assign) int flags;

/**
 * \note Unavailable, handled by `VLCRendererDiscoverer`
 * \see VLCRendererDiscoverer
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
