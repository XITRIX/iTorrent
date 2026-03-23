/*****************************************************************************
 * VLCMediaListPlayer.h: VLCKit.framework VLCMediaListPlayer implementation
 *****************************************************************************
 * Copyright (C) 2009 Pierre d'Herbemont
 * Partial Copyright (C) 2009-2013 Felix Paul Kühne
 * Copyright (C) 2009-2019 VLC authors and VideoLAN

 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Soomin Lee <bubu # mikan.io>
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

@class VLCMedia, VLCMediaPlayer, VLCMediaList, VLCMediaListPlayer;

NS_ASSUME_NONNULL_BEGIN

/**
 * VLCRepeatMode
 * (don't repeat anything, repeat one, repeat all)
 */
typedef NS_ENUM(NSInteger, VLCRepeatMode) {
    VLCDoNotRepeat,
    VLCRepeatCurrentItem,
    VLCRepeatAllItems
};

@protocol VLCMediaListPlayerDelegate <NSObject>
@optional
/**
 * Sent when VLCMediaListPlayer has finished playing.
 */
- (void)mediaListPlayerFinishedPlayback:(VLCMediaListPlayer *)player;

/**
 * Sent when VLCMediaListPlayer going to play next media
 */
- (void)mediaListPlayer:(VLCMediaListPlayer *)player
              nextMedia:(VLCMedia *)media;

/**
 * Sent when VLCMediaListPlayer is stopped.
 * Internally or by using the stop()
 * \see stop
 */
- (void)mediaListPlayerStopped:(VLCMediaListPlayer *)player;
@end

/**
 * A media list player, which eases the use of playlists
 */
OBJC_VISIBLE
@interface VLCMediaListPlayer : NSObject

/**
 * setter/getter for mediaList to play within the player
 * \note This list is erased when setting a rootMedia on the list player instance
 */
@property (readwrite, nullable) VLCMediaList *mediaList;

/**
 * rootMedia - Use this method to play a media and its subitems.
 * This will erase mediaList.
 * Setting mediaList will erase rootMedia.
 */
@property (readwrite, nullable) VLCMedia *rootMedia;

/**
 * the media player instance used for playback by the list player
 */
@property (readonly) VLCMediaPlayer *mediaPlayer;

/**
 * Receiver's delegate
 */
@property (nonatomic, weak, nullable) id <VLCMediaListPlayerDelegate> delegate;

/**
 * initializer with a certain drawable
 * \note drawable can also be set later
 */
- (instancetype)initWithDrawable:(id)drawable;
/**
 * initializer with a custom options
 * \note This is will initialize a new VLCLibrary instance, which WILL have a major memory impact
 */
- (instancetype)initWithOptions:(NSArray *)options;
/**
 * initializer with a certain drawable and options
 * \see initWithDrawable
 * \see initWithOptions
 */
- (instancetype)initWithOptions:(nullable NSArray *)options andDrawable:(nullable id)drawable;

/**
 * start playback
 */
- (void)play;
/**
 * pause playback
 */
- (void)pause;
/**
 * stop playback
 */
- (void)stop;

/**
 * play next item
 * \returns YES on success, NO if there is no such item
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL next;
/**
 * play previous item
 * \returns YES on success, NO if there is no such item
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL previous;

/**
 * play an item at a given index in the media list attached to the player
 */
- (void)playItemAtNumber:(NSNumber *)index;

/**
 * Playmode selection (don't repeat anything, repeat one, repeat all)
 * See VLCRepeatMode.
 */
@property (readwrite) VLCRepeatMode repeatMode;

/**
 * media must be in the current media list.
 */
- (void)playMedia:(VLCMedia *)media;

@end

NS_ASSUME_NONNULL_END
