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
#import <FBAudienceNetwork/FBAdExtraHint.h>
#import <FBAudienceNetwork/FBNativeAd.h>
#import <FBAudienceNetwork/FBNativeAdsManager.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Additional functionality on top of FBNativeAdsManager to assist in using native ads within a UICollectionView. This
 class contains a mechanism to map indexPaths to native ads in a stable manner as well as helpers which assist in doing
 the math to include ads at a regular interval within a collection view.
 */
FB_CLASS_EXPORT
@interface FBNativeAdCollectionViewAdProvider : NSObject

/**
 Passes delegate methods from FBNativeAd. Separate delegate calls will be made for each native ad contained.
 */
@property (nonatomic, weak, nullable) id<FBNativeAdDelegate> delegate;

/**
 FBAdExtraHint to provide extra info. Note: FBAdExtraHint is deprecated in AudienceNetwork. See FBAdExtraHint for more
 details

 */
@property (nonatomic, strong, nullable) FBAdExtraHint *extraHint;

/**
 Initializes a FBNativeAdCollectionViewAdProvider.


 @param manager The FBNativeAdsManager which is consumed by this class.
 */
- (instancetype)initWithManager:(FBNativeAdsManager *)manager NS_DESIGNATED_INITIALIZER;

/**
 Retrieves a native ad for an indexPath, will return the same ad for a given indexPath until the native ads manager is
 refreshed. This method is intended for usage with a collection view and specifically the caller is recommended to wait
 until  collectionView:cellForRowAtIndexPath: to ensure getting the best native ad for the given collection cell.


 @param collectionView The collectionView where native ad will be used
 @param indexPath The indexPath to use as a key for this native ad
 @return A FBNativeAd which is loaded and ready to be used.
 */
- (FBNativeAd *)collectionView:(UICollectionView *)collectionView nativeAdForRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 Support for evenly distributed native ads within a collection view. Computes whether this cell is an ad or not.


 @param indexPath The indexPath of the cell within the collection view
 @param stride The frequency that native ads are to appear within the collection view
 @return Boolean indicating whether the cell at the path is an ad
 */
- (BOOL)isAdCellAtIndexPath:(NSIndexPath *)indexPath forStride:(NSUInteger)stride;

/**
 Support for evenly distributed native ads within a collection view. Adjusts a non-ad cell indexPath to the indexPath
 it would be in a collection with no ads.


 @param indexPath The indexPath to of the non-ad cell
 @param stride The frequency that native ads are to appear within the collection view
 @return An indexPath adjusted to what it would be in a collection view with no ads
 */
- (nullable NSIndexPath *)adjustNonAdCellIndexPath:(NSIndexPath *)indexPath forStride:(NSUInteger)stride;

/**
 Support for evenly distributed native ads within a collection view. Adjusts the total count of cells within the
 collection view to account for the ad cells.


 @param count The count of cells in the collection view not including ads
 @param stride The frequency that native ads are to appear within the collection view
 @return The total count of cells within the collection view including both ad and non-ad cells
 */
- (NSUInteger)adjustCount:(NSUInteger)count forStride:(NSUInteger)stride;

@end

NS_ASSUME_NONNULL_END
