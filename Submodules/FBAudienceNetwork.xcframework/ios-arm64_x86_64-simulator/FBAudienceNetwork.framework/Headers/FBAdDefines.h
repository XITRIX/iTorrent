/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#ifndef FBAudienceNetwork_FBAdDefines_h
#define FBAudienceNetwork_FBAdDefines_h

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmacro-redefined"

#ifdef __cplusplus
#define FB_EXTERN_C_BEGIN extern "C" {
#define FB_EXTERN_C_END }
#else
#define FB_EXTERN_C_BEGIN
#define FB_EXTERN_C_END
#endif

#ifdef __cplusplus
#define FB_EXPORT extern "C" __attribute__((visibility("default")))
#else
#define FB_EXPORT extern __attribute__((visibility("default")))
#endif

#define FB_CLASS_EXPORT __attribute__((visibility("default")))
#define FB_DEPRECATED __attribute__((deprecated))
#define FB_DEPRECATED_WITH_MESSAGE(M) __attribute__((deprecated(M)))

#if __has_feature(objc_generics)
#define FB_NSArrayOf(x) NSArray<x>
#define FB_NSMutableArrayOf(x) NSMutableArray<x>
#define FB_NSDictionaryOf(x, y) NSDictionary<x, y>
#define FB_NSMutableDictionaryOf(x, y) NSMutableDictionary<x, y>
#define FB_NSSetOf(x) NSSet<x>
#define FB_NSMutableSetOf(x) NSMutableSet<x>
#else
#define FB_NSArrayOf(x) NSArray
#define FB_NSMutableArrayOf(x) NSMutableArray
#define FB_NSDictionaryOf(x, y) NSDictionary
#define FB_NSMutableDictionaryOf(x, y) NSMutableDictionary
#define FB_NSSetOf(x) NSSet
#define FB_NSMutableSetOf(x) NSMutableSet
#define __covariant
#endif

#if !__has_feature(nullability)
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#define nullable
#define __nullable
#endif

#ifndef FB_SUBCLASSING_RESTRICTED
#if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#define FB_SUBCLASSING_RESTRICTED __attribute__((objc_subclassing_restricted))
#else
#define FB_SUBCLASSING_RESTRICTED
#endif
#endif

#pragma GCC diagnostic pop

#endif  // FBAudienceNetwork_FBAdDefines_h
