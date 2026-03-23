/*****************************************************************************
 * VLCLogging.h: [Mobile/TV]VLCKit.framework VLCLogging header
 *****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Maxime Chapelet <umxprime # videolabs.io>
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

#ifndef VLCLogging_h
#define VLCLogging_h

NS_ASSUME_NONNULL_BEGIN

/**
 * \brief Levels to filter log messages
 * \see VLCLogging
 */
typedef NS_ENUM(int, VLCLogLevel) {
    kVLCLogLevelError = 0,  /// To only print errors
    kVLCLogLevelWarning,    /// To only print errors and warnings
    kVLCLogLevelInfo,       /// To only print infos, errors and warnings
    kVLCLogLevelDebug       /// To print all messages
};

/**
 * Detailed infos associated with a log message
 */
@interface VLCLogContext: NSObject
/**
 * Emitter (temporarily) unique object ID or 0
 */
@property (nonatomic, readonly) uintptr_t objectId;

/**
 * Emitter object type name
 */
@property (nonatomic, readonly) NSString *objectType;

/**
 * Emitter module
 */
@property (nonatomic, readonly) NSString *module;

/**
 * Additional header (used by VLM media) or nil
 */
@property (nonatomic, readonly, nullable) NSString *header;

/**
 * Source code file name or nil
 */
@property (nonatomic, readonly, nullable) NSString *file;

/**
 * Source code file line number or -1
 */
@property (nonatomic, readonly) int line;

/**
 * Source code calling function name or NULL
 */
@property (nonatomic, readonly, nullable) NSString *function;

/**
 * Emitter thread ID
 */
@property (nonatomic, readonly) unsigned long threadId;

@end

/**
 * Flags used by VLCLogMessageFormatting protocol's contextFlags property
 */
typedef NS_OPTIONS(int, VLCLogContextFlag) {
    kVLCLogLevelContextNone = 0,                /// Log no additionnal context
    kVLCLogLevelContextModule = 1<<0,           /// Log responsible module and object type
    kVLCLogLevelContextFileLocation = 1<<1,     /// Log file path and line number if available
    kVLCLogLevelContextCallingFunction = 1<<2,  /// Log calling function name
    kVLCLogLevelContextCustom = 1<<3,           /// Log custom context, see -[VLCLogMessageFormatting customContext] property
    kVLCLogLevelContextAll = 0xF                /// Log all available additional context
};

/**
 * \brief Protocol implemented by any object that may format log messages with their context
 * \discussion Its use is optional for any custom logger implementation but is actually being used in VLCKit loggers
 * \see VLCFormattedMessageLogging
 */
@protocol VLCLogMessageFormatting <NSObject>

/**
 * \brief Enable/disable logging context options
 * \see VLCLogContextFlag
 */
@property (readwrite, nonatomic) VLCLogContextFlag contextFlags;

/**
 * \brief Custom infos that might be appended to log messages.
 * \discussion Ideally the customContext object should respond to the `description` selector in order to return a `NSString`
 *
 * \note A `description` method implementation is expected by VLCLogMessageFormatter
 */
@property (readwrite, nonatomic, nullable) id customContext;

@required
/**
 * \brief The implementation should convert log infos to a string that will be used by a logger
 * \discussion This must be implemented by any formatter to be called each time a logger handles a message
 */
- (NSString *)formatWithMessage:(NSString *)message
                       logLevel:(VLCLogLevel)level
                        context:(nullable VLCLogContext *)context;

@end

/**
 * \brief Protocol implemented by any logger used in -[VLCLibrary loggers]
 * \see -[VLCLibrary loggers]
 */
@protocol VLCLogging <NSObject>
@required
/**
 * \brief Gets/sets this to filter in/out messages to handle
 * \see VLCLogLevel
 */
@property (readwrite, nonatomic) VLCLogLevel level;

/**
 * \brief Called by the VLCLibrary logging handler when a log message is delivered
 * \param message The log message
 * \param level The log level
 * \param context The log context, can be nil
 */
- (void)handleMessage:(NSString *)message
             logLevel:(VLCLogLevel)level
              context:(nullable VLCLogContext *)context;
@end

/**
 * \brief Protocol implemented by any logger that use a formatter
 * \note Its use is optional for any custom logger implementation but is actually being used in VLCKit loggers
 * \see -[VLCLibrary loggers]
 * \see VLCConsoleLogger
 * \see VLCFileLogger
 */
@protocol VLCFormattedMessageLogging <VLCLogging>
@required

@property (nonatomic, readwrite) id<VLCLogMessageFormatting> formatter;

@end

NS_ASSUME_NONNULL_END

#endif /* VLCLogHandler_h */
