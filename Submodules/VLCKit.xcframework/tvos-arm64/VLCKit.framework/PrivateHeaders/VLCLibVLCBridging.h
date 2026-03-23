/*****************************************************************************
 * VLCLibVLCbridging.h: VLCKit.framework VLCLibVLCBridging (Private) header
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2007 VLC authors and VideoLAN
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

#import <VLCLibrary.h>
#if !TARGET_OS_IPHONE
#import <VLCStreamOutput.h>
#endif // !TARGET_OS_IPHONE
#import <VLCMediaPlayer.h>
#import <VLCMediaList.h>
#import <VLCMedia.h>
#import <VLCAudio.h>
#import <VLCMediaMetaData.h>
#import <VLCAudioEqualizer.h>
#import <VLCMediaPlayerTitleDescription.h>
#if !TARGET_OS_TV
#import <VLCRendererItem.h>
#endif // !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

/**
 * Bridges functionality between libvlc and VLCMediaList implementation.
 */
@interface VLCMediaList (LibVLCBridging)
/* Factories */
/**
 * Manufactures new object wrapped around specified media list.
 * \param p_new_mlist LibVLC media list pointer.
 * \return Newly create media list instance using specified media list
 * pointer.
 */
+ (id)mediaListWithLibVLCMediaList:(void *)p_new_mlist;

/* Initializers */
/**
 * Initializes new object wrapped around specified media list.
 * \param p_new_mlist LibVLC media list pointer.
 * \return Newly create media list instance using specified media list
 * pointer.
 */
- (id)initWithLibVLCMediaList:(void *)p_new_mlist;

/* Properties */
@property (readonly) void * libVLCMediaList;    ///< LibVLC media list pointer.
@end

/**
 * Bridges functionality between libvlc and VLCMedia implementation.
 */
@interface VLCMedia (LibVLCBridging)
/* Factories */
/**
 * Manufactures new object wrapped around specified media descriptor.
 * \param md LibVLC media descriptor pointer.
 * \return Newly created media instance using specified descriptor.
 */
+ (nullable instancetype)mediaWithLibVLCMediaDescriptor:(void *)md;

/* Initializers */
/**
 * Initializes new object wrapped around specified media descriptor.
 * \param md LibVLC media descriptor pointer.
 * \return Newly created media instance using specified descriptor.
 */
- (nullable instancetype)initWithLibVLCMediaDescriptor:(void *)md;

+ (nullable instancetype)mediaWithMedia:(VLCMedia *)media andLibVLCOptions:(NSDictionary *)options;

/**
 * Returns the receiver's internal media descriptor pointer.
 * \return The receiver's internal media descriptor pointer.
 */
@property (readonly) void * libVLCMediaDescriptor;
@end

/**
 * Bridges functionality between VLCMedia and VLCMediaPlayer
 */
@interface VLCMediaPlayer (LibVLCBridging)

/* Properties */
@property (readonly) void * libVLCMediaPlayer;    ///< LibVLC media list pointer.
@end

/**
 * Bridges functionality between VLCMediaPlayer and LibVLC core
 */
@interface VLCMedia (VLCMediaPlayerBridging)
/**
 * Set's the length of the media object.  This value becomes available once the
 * media object is being played.
 * \param value the length value
 */
- (void)setLength:(VLCTime *)value;
@end

/**
 * Bridges functionality between VLCLibrary and LibVLC core.
 */
@interface VLCLibrary (VLCLibVLCBridging)
/**
 * Shared singleton instance of libvlc library instance.
 * \return libvlc pointer of library instance.
 */
+ (void *)sharedInstance;

/**
 * Instance of libvlc library instance.
 * \return libvlc pointer of library instance.
 */
@property (readonly) void * instance;
@end

/**
 * Bridges functionality between VLCLibrary and VLCAudio.
 */
@interface VLCLibrary (VLCAudioBridging)
/**
 * Called by VLCAudio, each library has a singleton VLCaudio instance.  VLCAudio
 * calls this function to let the VLCLibrary instance know how to get in touch
 * with the VLCAudio instance.  TODO: Each media player instance should have it's
 * own audio instance...not each library instance.
 */
- (void)setAudio:(VLCAudio *)value;
@end

/**
 * Bridges functionality between VLCAudio and VLCLibrary.
 */
@interface VLCAudio (VLCAudioBridging)
/* Initializers */
/**
 * Initializes a new object using the specified mediaPlayer instance.
 * \return Newly created audio object using specified VLCMediaPlayer instance.
 */
- (id)initWithMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
@end

#if !TARGET_OS_TV
/**
 * Bridges functionality between libvlc and VLCRendererItem implementation.
 */
@interface VLCRendererItem (VLCRendererItemBridging)
/**
 * Initializer method to create an VLCRendererItem with an `libvlc_renderer_item_t *`.
 *
 * \param renderer item.
 * \note This initializer is not meant to be used externally.
 * \return An instance of `VLCRendererItem`, can be nil.
 */
- (instancetype)initWithRendererItem:(void *)item;

/**
 * Returns a `libvlc_renderer_item_t *` renderer item.
 * \return Renderer item.
 */
- (void *)libVLCRendererItem;

@end
#endif // !TARGET_OS_TV
/**
 * TODO: Documentation
 */
#if !TARGET_OS_IPHONE
@interface VLCStreamOutput (LibVLCBridge)
- (NSString *)representedLibVLCOptions;
@end
#endif


/**
 * Bridges functionality between libvlc and VLCMediaTrack implementation.
 */
@interface VLCMediaTrack (LibVLCBridging)

- (nullable instancetype)initWithMediaTrack:(libvlc_media_track_t *)track;

@end

/**
 * Bridges functionality between libvlc and VLCMediaAudioTrack implementation.
 */
@interface VLCMediaAudioTrack (LibVLCBridging)

- (nullable instancetype)initWithAudioTrack:(libvlc_audio_track_t *)audio;

@end

/**
 * Bridges functionality between libvlc and VLCMediaVideoTrack implementation.
 */
@interface VLCMediaVideoTrack (LibVLCBridging)

- (nullable instancetype)initWithVideoTrack:(libvlc_video_track_t *)video;

@end

/**
 * Bridges functionality between libvlc and VLCMediaTextTrack implementation.
 */
@interface VLCMediaTextTrack (LibVLCBridging)

- (nullable instancetype)initWithSubtitleTrack:(libvlc_subtitle_track_t *)subtitle;

@end

/**
 * Bridges functionality between libvlc and VLCMediaMetaData implementation.
 */
@interface VLCMediaMetaData (LibVLCBridging)

- (instancetype)initWithMedia:(VLCMedia *)media;

- (void)handleMediaMetaChanged:(const libvlc_meta_t)type;

@end

/**
 * Bridges functionality between libvlc and VLCMediaPlayerTrack implementation.
 */
@interface VLCMediaPlayerTrack (LibVLCBridging)

- (nullable instancetype)initWithMediaTrack:(libvlc_media_track_t *)track mediaPlayer:(VLCMediaPlayer *)mediaPlayer;

- (nullable instancetype)initWithMediaTrack:(libvlc_media_track_t *)track NS_UNAVAILABLE;

@end

/**
 * Bridges functionality between libvlc and VLCAudioEqualizer implementation.
 */
@interface VLCAudioEqualizer (LibVLCBridging)

- (void)setMediaPlayer:(nullable VLCMediaPlayer *)mediaPlayer;

@end

/**
 * Bridges functionality between libvlc and VLCMediaPlayerChapterDescription implementation.
 */
@interface VLCMediaPlayerChapterDescription (LibVLCBridging)

- (instancetype)initWithMediaPlayer:(VLCMediaPlayer *)mediaPlayer titleIndex:(const int)titleIndex chapterDescription:(libvlc_chapter_description_t *)chapter_description chapterIndex:(const int)chapterIndex;

@end

/**
 * Bridges functionality between libvlc and VLCMediaPlayerTitleDescription implementation.
 */
@interface VLCMediaPlayerTitleDescription (LibVLCBridging)

- (instancetype)initWithMediaPlayer:(VLCMediaPlayer *)mediaPlayer titleDescription:(libvlc_title_description_t *)title_description titleIndex:(const int)titleIndex;

- (void)navigate:(const libvlc_navigate_mode_t)navigate_mode;

@end

NS_ASSUME_NONNULL_END
