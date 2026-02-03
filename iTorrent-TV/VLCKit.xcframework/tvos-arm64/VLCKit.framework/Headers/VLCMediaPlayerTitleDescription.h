/*****************************************************************************
 * VLCMediaPlayerTitleDescription.h: VLCKit.framework VLCMediaPlayerTitleDescription header
 *****************************************************************************
 * Copyright (C) 2023 VLC authors and VideoLAN
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

@class VLCTime;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - VLCMediaPlayerChapterDescription

/**
 * VLCMediaPlayerChapterDescription
 */
NS_SWIFT_NAME(VLCMediaPlayer.ChapterDescription)
@interface VLCMediaPlayerChapterDescription : NSObject

/**
 * time-offset of the chapter in milliseconds
 */
@property (nonatomic, readonly) VLCTime *timeOffset;

/**
 * duration of the chapter in milliseconds
 */
@property (nonatomic, readonly) VLCTime *durationTime;

/**
 * chapter name
 */
@property (nonatomic, readonly, copy, nullable) NSString *name;

/**
 * chapter index
 */
@property (nonatomic, readonly) int chapterIndex;

/**
 * title index
 */
@property (nonatomic, readonly) int titleIndex;

/**
 * own media url
 */
@property (nonatomic, readonly, nullable) NSURL *mediaURL;

/**
 *  currently
 */
@property (nonatomic, getter=isCurrent, readonly) BOOL current;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * Set movie chapter (if applicable).
 */
- (void)setCurrent;

@end


#pragma mark - VLCMediaPlayerTitleType

/**
 * VLCMediaPlayerTitleType
 */
typedef NS_OPTIONS(unsigned, VLCMediaPlayerTitleType) {
    VLCMediaPlayerTitleTypeMenu         = 0x01,
    VLCMediaPlayerTitleTypeInteractive  = 0x02
} NS_SWIFT_NAME(VLCMediaPlayer.TitleType);


#pragma mark - VLCMediaPlayerTitleDescription

/**
 * VLCMediaPlayerTitleDescription
 */
NS_SWIFT_NAME(VLCMediaPlayer.TitleDescription)
@interface VLCMediaPlayerTitleDescription : NSObject

/**
 * duration in milliseconds
 */
@property (nonatomic, readonly) VLCTime *durationTime;

/**
 * title name
 */
@property (nonatomic, readonly, copy, nullable) NSString *name;

/**
 * info if item was recognized as a menu, interactive or plain content by the demuxer
 */
@property (nonatomic, readonly) VLCMediaPlayerTitleType titleType;

/**
 * description for chapters
 */
@property (nonatomic, readonly, copy) NSArray<VLCMediaPlayerChapterDescription *> *chapterDescriptions;

/**
 * title index
 */
@property (nonatomic, readonly) int titleIndex;

/**
 * own media url
 */
@property (nonatomic, readonly, nullable) NSURL *mediaURL;

/**
 * value of whether the title is a menu
 */
@property (nonatomic, readonly, getter=isMenu) BOOL menu;

/**
 *  currently
 */
@property (nonatomic, readonly, getter=isCurrent) BOOL current;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * Set movie title
 */
- (void)setCurrent;

/**
 * Navigate through DVD Menu Activate
 */
- (void)navigateActivate;

/**
 * Navigate through DVD Menu Up
 */
- (void)navigateUp;

/**
 * Navigate through DVD Menu Down
 */
- (void)navigateDown;

/**
 * Navigate through DVD Menu Left
 */
- (void)navigateLeft;

/**
 * Navigate through DVD Menu Right
 */
- (void)navigateRight;

/**
 * Navigate through DVD Menu Popup
 */
- (void)navigatePopup;

@end

NS_ASSUME_NONNULL_END
