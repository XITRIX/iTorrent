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
#import <FBAudienceNetwork/FBNativeAdCollectionViewAdProvider.h>
#import <FBAudienceNetwork/FBNativeAdView.h>
#import <FBAudienceNetwork/FBNativeAdsManager.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Class which assists in putting FBNativeAdViews into UICollectionViews. This class manages the creation of
 UICollectionViewCells which host native ad views. Functionality is provided to create UICollectionCellViews as needed
 for a given indexPath as well as computing the height of the cells.
 */
FB_CLASS_EXPORT FB_SUBCLASSING_RESTRICTED @interface FBNativeAdCollectionViewCellProvider
    : FBNativeAdCollectionViewAdProvider

/**
 Method to create a FBNativeAdCollectionViewCellProvider.


 @param manager The naitve ad manager consumed by this provider
 @param type The type of this native ad template. For more information, consult FBNativeAdViewType.
 */
- (instancetype)initWithManager:(FBNativeAdsManager *)manager forType:(FBNativeAdViewType)type;

/**
 Method to create a FBNativeAdCollectionViewCellProvider.


 @param manager The naitve ad manager consumed by this provider
 @param type The type of this native ad template. For more information, consult FBNativeAdViewType.
 @param attributes The layout of this native ad template. For more information, consult FBNativeAdViewLayout.
 */
- (instancetype)initWithManager:(FBNativeAdsManager *)manager
                        forType:(FBNativeAdViewType)type
                  forAttributes:(FBNativeAdViewAttributes *)attributes NS_DESIGNATED_INITIALIZER;

/**
 Helper method for implementors of UICollectionViewDataSource who would like to host native ad UICollectionViewCells in
 their collection view.
 */
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 Helper method for implementors of UICollectionViewDelegate who would like to host native ad UICollectionViewCells in
 their collection view.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
