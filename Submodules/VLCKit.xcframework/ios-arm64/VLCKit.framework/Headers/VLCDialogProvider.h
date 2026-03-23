/*****************************************************************************
 * VLCDialogProvider.h: an implementation of the libvlc dialog API
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

@class VLCLibrary;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VLCDialogQuestionType) {
    VLCDialogQuestionNormal,
    VLCDialogQuestionWarning,
    VLCDialogQuestionCritical,
};

/**
 * the protocol to use if you decide to run a custom dialog appearance
 */
@protocol VLCCustomDialogRendererProtocol <NSObject>

/**
 * called when VLC wants to show an error
 * \param error the dialog title
 * \param message the error message
 */
- (void)showErrorWithTitle:(NSString *)error
      message:(NSString *)message;

/**
 * called when user logs in to something
 * If VLC includes a keychain module for your platform, a user can store stuff
 * \param title login dialog title
 * \param message an explaining message
 * \param username a default username within context
 * \param askingForStorage indicator whether storing is even a possibility
 * \param reference you need to send the results to
 */
- (void)showLoginWithTitle:(NSString *)title
                   message:(NSString *)message
           defaultUsername:(nullable NSString *)username
          askingForStorage:(BOOL)askingForStorage
             withReference:(NSValue *)reference;

/**
 * called when VLC needs the user to decide something
 * \param title the dialog title
 * \param message an explaining message text
 * \param questionType a question type
 * \param cancelString cancel button text
 * \param action1String action 1 text
 * \param action2String action 2 text
 * \param reference you need to send the action to
 */
- (void)showQuestionWithTitle:(NSString *)title
                      message:(NSString *)message
                         type:(VLCDialogQuestionType)questionType
                 cancelString:(nullable NSString *)cancelString
                action1String:(nullable NSString *)action1String
                action2String:(nullable NSString *)action2String
                withReference:(NSValue *)reference;

/**
 * called when VLC wants to show some progress
 * \param title the dialog title
 * \param message an explaining message
 * \param isIndeterminate indicator whether progress indeterminate
 * \param position initial progress position
 * \param cancelString optional string for cancel button if operation is cancellable
 * \param reference VLC will include in updates
 */
- (void)showProgressWithTitle:(NSString *)title
                      message:(NSString *)message
              isIndeterminate:(BOOL)isIndeterminate
                     position:(float)position
                 cancelString:(nullable NSString *)cancelString
                withReference:(NSValue *)reference;

/** called when VLC wants to update an existing progress dialog
 * \param reference to the existing progress dialog
 * \param message updated message
 * \param position current position
 */
- (void)updateProgressWithReference:(NSValue *)reference
                            message:(nullable NSString *)message
                            position:(float)position;

/** VLC decided to destroy a dialog
 * \param reference to the dialog to destroy
 */
- (void)cancelDialogWithReference:(NSValue *)reference;

@end


/**
 * dialog provider base class
 * \note For iOS and tvOS, there are useable implementations available which don't require the use of a custom renderer
 */
OBJC_VISIBLE
@interface VLCDialogProvider : NSObject

/**
 * initializer method to run the dialog provider instance on a specific library instance
 *
 * \param library the VLCLibrary instance
 * \param customUI enable custom UI mode
 * \note if library param is NULL, [VLCLibrary sharedLibrary] will be used
 * \return the dialog provider instance, can be NULL on malloc failures
 */
- (nullable instancetype)initWithLibrary:(nullable VLCLibrary *)library
                                 customUI:(BOOL)customUI;

/**
 * initializer method to run the dialog provider instance on a specific library instance
 *
 * \return the object set
 */
@property (weak, readwrite, nonatomic, nullable) id<VLCCustomDialogRendererProtocol> customRenderer;

/**
 * if you requested custom UI mode for dialogs, use this method respond to a login dialog
 * \param username or NULL if cancelled
 * \param password or NULL if cancelled
 * \param dialogReference reference to the dialog you respond to
 * \param store shall VLC store the login securely?
 * \note This method does not have any effect if you don't use custom UI mode */
- (void)postUsername:(NSString *)username
         andPassword:(NSString *)password
  forDialogReference:(NSValue *)dialogReference
               store:(BOOL)store;

/**
 * if you requested custom UI mode for dialogs, use this method respond to a question dialog
 * \param buttonNumber the button number the user pressed, use 3 if s/he cancelled, otherwise respectively 1 or 2 depending on the selected action
 * \param dialogReference reference to the dialog you respond to
 * \note This method does not have any effect if you don't use custom UI mode */
- (void)postAction:(int)buttonNumber
forDialogReference:(NSValue *)dialogReference;

/**
 * if you requested custom UI mode for dialogs, use this method to cancel a progress dialog
 * \param dialogReference reference to the dialog you want to cancel
 * \note This method does not have any effect if you don't use custom UI mode */
- (void)dismissDialogWithReference:(NSValue *)dialogReference;

@end

NS_ASSUME_NONNULL_END
