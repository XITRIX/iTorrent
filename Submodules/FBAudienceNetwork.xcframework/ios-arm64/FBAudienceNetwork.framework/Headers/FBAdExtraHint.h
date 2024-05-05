/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBAudienceNetwork/FBAdDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *FBAdExtraHintKeyword NS_STRING_ENUM;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordAccessories;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordArtHistory;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordAutomotive;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordBeauty;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordBiology;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordBoardGames;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordBusinessSoftware;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordBuyingSellingHomes;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordCats;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordCelebrities;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordClothing;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordComicBooks;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordDesktopVideo;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordDogs;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordEducation;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordEmail;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordEntertainment;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordFamilyParenting;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordFashion;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordFineArt;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordFoodDrink;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordFrenchCuisine;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordGovernment;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordHealthFitness;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordHobbies;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordHomeGarden;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordHumor;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordInternetTechnology;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordLargeAnimals;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordLaw;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordLegalIssues;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordLiterature;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordMarketing;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordMovies;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordMusic;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordNews;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordPersonalFinance;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordPets;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordPhotography;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordPolitics;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordRealEstate;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordRoleplayingGames;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordScience;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordShopping;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordSociety;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordSports;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordTechnology;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordTelevision;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordTravel;
extern FBAdExtraHintKeyword const FBAdExtraHintKeywordVideoComputerGames;

FB_CLASS_EXPORT
@interface FBAdExtraHint : NSObject

@property (nonatomic, copy, nullable)
    NSString *contentURL FB_DEPRECATED_WITH_MESSAGE("Extra hints are no longer used in Audience Network");

@property (nonatomic, copy, nullable)
    NSString *extraData FB_DEPRECATED_WITH_MESSAGE("Extra hints are no longer used in Audience Network");

@property (nonatomic, copy, nullable)
    NSString *mediationData FB_DEPRECATED_WITH_MESSAGE("Extra hints are no longer used in Audience Network");

- (instancetype)initWithKeywords:(NSArray<FBAdExtraHintKeyword> *)keywords
    FB_DEPRECATED_WITH_MESSAGE("Keywords are no longer used in Audience Network");

- (void)addKeyword:(FBAdExtraHintKeyword)keyword
    FB_DEPRECATED_WITH_MESSAGE("Keywords are no longer used in Audience Network");

- (void)removeKeyword:(FBAdExtraHintKeyword)keyword
    FB_DEPRECATED_WITH_MESSAGE("Keywords are no longer used in Audience Network");

@end

NS_ASSUME_NONNULL_END
