//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAResultMatcher.h"

#define OSM_WIKI_CATEGORY @"osmwiki"
#define SPEED_CAMERA @"speed_camera"
#define WIKI_LANG @"wiki_lang"
#define WIKI_PLACE @"wiki_place"
#define ROUTE_ARTICLE_POINT @"route_article_point"

#define kSearchLimit 200
const static int kSearchRadiusKm[] = {1, 2, 5, 10, 20, 50, 100};

@class OAPOI, OAPOIType, OAPOIBaseType, OAPOICategory, OAPOIFilter;
@class OASearchPoiTypeFilter, OAPOIUIFilter;

@protocol OAPOISearchDelegate

- (void) poiFound:(OAPOI *)poi;
- (void) searchDone:(BOOL)wasInterrupted;

@end

@interface OAPOIHelper : NSObject

@property (nonatomic, readonly) BOOL isSearchDone;
@property (nonatomic, assign) int searchLimit;

@property (nonatomic, readonly) NSArray<OAPOIType *> *poiTypes;
@property (nonatomic, readonly) NSMapTable<NSString *, OAPOIType *> *poiTypesByName;
@property (nonatomic, readonly) NSArray<OAPOICategory *> *poiCategories;
@property (nonatomic, readonly) NSArray<OAPOICategory *> *poiCategoriesNoOther;
@property (nonatomic, readonly) OAPOICategory *otherPoiCategory;
@property (nonatomic, readonly) OAPOICategory *otherMapCategory;
@property (nonatomic, readonly) NSArray<OAPOIFilter *> *poiFilters;

@property (weak, nonatomic) id<OAPOISearchDelegate> delegate;
@property (weak, nonatomic) id<OAPOISearchDelegate> tempDelegate;

+ (OAPOIHelper *) sharedInstance;

- (BOOL) isInit;

- (void) updatePhrases;

- (BOOL) isRegisteredType:(OAPOICategory *)t;
- (NSArray *) poiFiltersForCategory:(NSString *)categoryName;

- (OAPOIType *) getPoiType:(NSString *)tag value:(NSString *)value;
- (OAPOIType *) getPoiTypeByName:(NSString *)name;
- (OAPOIType *) getPoiTypeByKey:(NSString *)name;
- (OAPOIBaseType *) getAnyPoiTypeByName:(NSString *)name;
- (OAPOIType *) getPoiTypeByCategory:(NSString *)category name:(NSString *)name;
- (OAPOIType *) getPoiTypeByKeyInCategory:(OAPOICategory *)category name:(NSString *)name;
- (OAPOIBaseType *) getAnyPoiAdditionalTypeByKey:(NSString *)name;
- (OAPOIType *) getTextPoiAdditionalByKey:(NSString *)name;
- (NSString *) getPoiAdditionalCategoryIcon:(NSString *)category;
- (NSString *) replaceDeprecatedSubtype:(NSString *)subtype;

- (NSString *) getPhraseByName:(NSString *)name;
- (NSString *) getPhraseByName:(NSString *)name withDefatultValue:(BOOL)withDefatultValue;
- (NSString *) getPhraseENByName:(NSString *)name;
- (NSString *) getSynonymsByName:(NSString *)name;
- (NSString *) getPhrase:(OAPOIBaseType *)type;
- (NSString *) getPhraseEN:(OAPOIBaseType *)type;

-(NSString *)getPoiStringWithoutType:(OAPOI *)poi;
-(NSString *)getFormattedOpeningHours:(OAPOI *)poi;

- (NSArray<OAPOICategory *> *) getCategories:(BOOL)includeMapCategory;
- (OAPOICategory *) getPoiCategoryByName:(NSString *)name;
- (OAPOICategory *) getPoiCategoryByName:(NSString *)name create:(BOOL)create;

- (NSArray<OAPOIBaseType *> *) getTopVisibleFilters;
- (OAPOICategory *) getOsmwiki;
- (NSArray<NSString *> *)getAllAvailableWikiLocales;
- (NSString *) getAllLanguagesTranslationSuffix;

- (void) findPOIsByKeyword:(NSString *)keyword;
- (void) findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)category poiTypeName:(NSString *)type radiusIndex:(int *)radiusIndex;
- (void) findPOIsByFilter:(OAPOIUIFilter *)filter radiusIndex:(int *)radiusIndex;
- (OAPOIType *) getDefaultOtherCategoryType;

-(NSDictionary<NSString *, OAPOIType *> *)getAllTranslatedNames:(BOOL)skipNonEditable;
- (NSString *) getTranslation:(NSString *)keyName;

+ (NSArray<OAPOI *> *) findPOIsByFilter:(OASearchPoiTypeFilter *)filter topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *) findPOIsByName:(NSString *)query topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *) searchPOIsOnThePath:(NSArray<CLLocation *> *)locations radius:(double)radius filter:(OASearchPoiTypeFilter *)filter matcher:(OAResultMatcher<OAPOI *> *)matcher;
+ (UIImage *)getCustomFilterIcon:(OAPOIUIFilter *) filter;

- (BOOL) breakSearch;
- (BOOL) isNameTag:(NSString *)tag;

+ (OAPOI *) findPOIByOsmId:(long long)osmId lat:(double)lat lon:(double)lon;
+ (OAPOI *) findPOIByName:(NSString *)name lat:(double)lat lon:(double)lon;
+ (OAPOI *) findPOIByOriginName:(NSString *)originName lat:(double)lat lon:(double)lon;

@end
