/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/***
 * This is a bridge file for Audience Network Unity SDK.
 *
 * This file may be used to build your own Audience Network iOS SDK wrapper,
 * but note that we don't support customisations of the Audience Network codebase.
 *
 ***/

#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdBridgeContainer.h>
#import <FBAudienceNetwork/FBAdDefines.h>

FB_EXTERN_C_BEGIN

// External to this project
typedef NS_ENUM(NSInteger, FBGLViewController) {
    FBGLViewControllerNone,
    FBGLViewControllerUnity,
    FBGLViewControllerCocos2D,
};

__attribute__((weak)) extern UIViewController *UnityGetGLViewController(void);
__attribute__((__always_inline__)) extern FBGLViewController fbad_Cocos2DGetGLViewController(
    UIViewController **glViewController);

__attribute__((__always_inline__)) extern UIViewController *fbad_GetGLViewController(void);
__attribute__((__always_inline__)) extern FBGLViewController fbad_UnityGetGLViewController(
    UIViewController **glViewController);

FB_EXTERN_C_END
