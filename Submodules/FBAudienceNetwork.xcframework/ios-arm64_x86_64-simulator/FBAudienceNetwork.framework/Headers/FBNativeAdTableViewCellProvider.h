/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBAudienceNetwork/FBAdDefines.h>
#import <FBAudienceNetwork/FBNativeAd.h>
#import <FBAudienceNetwork/FBNativeAdTableViewAdProvider.h>
#import <FBAudienceNetwork/FBNativeAdView.h>
#import <FBAudienceNetwork/FBNativeAdsManager.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Class which assists in putting FBNativeAdViews into UITableViews. This class manages the creation of UITableViewCells
 which host native ad views. Functionality is provided to create UITableCellViews as needed for a given indexPath as
 well as computing the height of the cells.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBNativeAdTableViewCellProvider
    : FBNativeAdTableViewAdProvider<UITableViewDataSource>

/**
 Initializes a FBNativeAdTableViewCellProvider.


 @param manager The naitve ad manager consumed by this provider
 @param type The type of this native ad template. For more information, consult FBNativeAdViewType.
 */
- (instancetype)initWithManager:(FBNativeAdsManager *)manager forType:(FBNativeAdViewType)type;

/**
 Initializes a FBNativeAdTableViewCellProvider.


 @param manager The naitve ad manager consumed by this provider
 @param type The type of this native ad template. For more information, consult FBNativeAdViewType.
 @param attributes The layout of this native ad template. For more information, consult FBNativeAdViewLayout.
 */
- (instancetype)initWithManager:(FBNativeAdsManager *)manager
                        forType:(FBNativeAdViewType)type
                  forAttributes:(FBNativeAdViewAttributes *)attributes NS_DESIGNATED_INITIALIZER;

/**
 Helper method for implementors of UITableViewDataSource who would like to host native ad UITableViewCells in their
 table view.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 Helper method for implementors of UITableViewDelegate who would like to host native ad UITableViewCells in their table
 view.
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 Helper method for implementors of UITableViewDelegate who would like to host native ad UITableViewCells in their table
 view.
 */
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
