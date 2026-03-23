/*****************************************************************************
 * VLCTranscoder.h: VLCKit.framework VLCTranscoder implementation
 *****************************************************************************
 * Copyright (C) 2018 Carola Nitz
 * Copyright (C) 2018 VLC authors and VideoLAN
 * $Id$
 *
 * Authors:  Carola Nitz <caro # videolan.org>
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
* Transcoder delegate allows to be notified about transcoding state
*/
@class VLCTranscoder;
@protocol VLCTranscoderDelegate <NSObject>

@optional
/**
 * Called when the transcoding finished
 * \param transcoder the transcoder object that finished
 * \param success if transcoding finished sucessfully or not
 */
- (void)transcode:(VLCTranscoder *)transcoder finishedSucessfully:(BOOL)success;

@end

/**
 * Provides an object to convert a subtitle file and moviefile into one.
 */
OBJC_VISIBLE
@interface VLCTranscoder: NSObject

/**
 * the delegate object implementing the optional protocol
 */
@property (weak, nonatomic, nullable) id<VLCTranscoderDelegate> delegate;

/**
 * Reencode and remuxes an srt and mp4 file to an mkv file with embedded subtitles either with VideoToolbox-based H264 encoding or VP80 is Videotoolbox is not available
 * \param srtPath path to srt file
 * \param mp4Path path to mp4 file
 * \param outPath path where the new file should be written to
 * \return an BOOL with the success status, returns NO if the subtitle file is not an srt or mp4File is not an mp4 file or the files don't exist at that path or transcoding failed for other reasons
 */

- (BOOL)reencodeAndMuxSRTFile:(NSString *)srtPath toMP4File:(NSString *)mp4Path outputPath:(NSString *)outPath;

@end

NS_ASSUME_NONNULL_END
