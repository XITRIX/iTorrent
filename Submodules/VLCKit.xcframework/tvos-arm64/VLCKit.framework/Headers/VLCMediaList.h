/*****************************************************************************
 * VLCMediaList.h: VLCKit.framework VLCMediaList header
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2015 Felix Paul Kühne
 * Copyright (C) 2007, 2015 VLC authors and VideoLAN
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * notification name if a list item was added
 */
FOUNDATION_EXPORT NSNotificationName const VLCMediaListItemAddedNotification NS_SWIFT_NAME(VLCMediaList.itemAddedNotification);
/**
 * notification name if a list item was deleted
 */
FOUNDATION_EXPORT NSNotificationName const VLCMediaListItemDeletedNotification NS_SWIFT_NAME(VLCMediaList.itemDeletedNotification);

@class VLCMedia;
@class VLCMediaList;

/**
 * VLCMediaListDelegate
 */
@protocol VLCMediaListDelegate <NSObject>
@optional
/**
 * delegate method triggered when a media was added to the list
 *
 * \param aMediaList the media list
 * \param media the media object that was added
 * \param index the index the media object was added at
 */
- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSUInteger)index;

/**
 * delegate method triggered when a media was removed from the list
 *
 * \param aMediaList the media list
 * \param index the index a media item was deleted at
 */
- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSUInteger)index;
@end

/**
 * VLCMediaList
 */
OBJC_VISIBLE
@interface VLCMediaList : NSObject

/**
 * initializer with a set of VLCMedia instances
 * \param array the NSArray of VLCMedia instances
 * \return instance of VLCMediaList equipped with the VLCMedia instances
 * \see VLCMedia
 */
- (instancetype)initWithArray:(nullable NSArray<VLCMedia *> *)array;

/* Operations */
/**
 * lock the media list from being edited by another thread
 */
- (void)lock;

/**
 * unlock the media list from being edited by another thread
 */
- (void)unlock;

/**
 * add a media to a read-write list
 *
 * \param media the media object to add
 * \return the index of the newly added media
 * \note this function silently fails if the list is read-only
 */
- (NSUInteger)addMedia:(VLCMedia *)media;

/**
 * add a media to a read-write list at a given position
 *
 * \param media the media object to add
 * \param index the index where to add the given media
 * \note this function silently fails if the list is read-only
 */
- (void)insertMedia:(VLCMedia *)media atIndex:(NSUInteger)index;

/**
 * remove media at position index and return true if the operation was successful.
 * An unsuccessful operation occurs when the index is greater than the medialists count
 *
 * \param index the index of the media to remove
 * \return boolean result of the removal operation
 * \note this function silently fails if the list is read-only
 */
- (BOOL)removeMediaAtIndex:(NSUInteger)index;

/**
 * retrieve a media from a given position
 *
 * \param index the index of the media you want
 * \return the media object
 */
- (nullable VLCMedia *)mediaAtIndex:(NSUInteger)index;

/**
 * retrieve the position of a media item
 *
 * \param media the media object to search for
 * \return The lowest index of the provided media in the list
 * If media does not exist in the list, returns NSNotFound.
 */
- (NSUInteger)indexOfMedia:(VLCMedia *)media;

/* Properties */
/**
 * count number of media items in the list
 * \return the number of media objects
 */
@property (readonly) NSInteger count;

/**
 * delegate property to listen to addition/removal events
 */
@property (weak, nonatomic, nullable) id<VLCMediaListDelegate> delegate;

/**
 * read-only property to check if the media list is writable or not
 * \return boolean value if the list is read-only
 */
@property (readonly) BOOL isReadOnly;

/**
 * read-only property to check if the media list is empty or not
 * \return boolean value if the list is empty or not.
 */
@property (readonly) BOOL isEmpty;

@end

NS_ASSUME_NONNULL_END
