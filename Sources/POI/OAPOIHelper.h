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

extern NSString * const OSM_WIKI_CATEGORY;
extern NSString * const SPEED_CAMERA ;
extern NSString * const WIKI_LANG;
extern NSString * const WIKI_PLACE;
extern NSString * const ROUTE_ARTICLE_POINT;

#define kSearchLimit 200
const static int kSearchRadiusKm[] = {1, 2, 5, 10, 20, 50, 100};

@class OAPOI, OAPOIType, OAPOIBaseType, OAPOICategory, OAPOIFilter;
@class OASearchPoiTypeFilter, OAPOIUIFilter, OATopIndexFilter;

@protocol OAPOISearchDelegate

- (void) poiFound:(OAPOI *)poi;
- (void) searchDone:(BOOL)wasInterrupted;

@end

@interface OAPOIHelper : NSObject

@property (nonatomic, readonly) NSArray<OAPOIType *> *poiTypes;
@property (nonatomic, readonly) NSMapTable<NSString *, OAPOIType *> *poiTypesByName;
@property (nonatomic, readonly) NSArray<OAPOICategory *> *poiCategories;
@property (nonatomic, readonly) NSArray<OAPOICategory *> *poiCategoriesNoOther;
@property (nonatomic, readonly) OAPOICategory *otherPoiCategory;
@property (nonatomic, readonly) OAPOICategory *otherMapCategory;
@property (nonatomic, readonly) NSArray<OAPOIFilter *> *poiFilters;

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
- (NSString *) getPoiTypeOptionalIcon:(NSString *)type;
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

- (OAPOIType *) getDefaultOtherCategoryType;
- (NSMutableArray<NSString *> *) getPublicTransportTypes;

-(NSDictionary<NSString *, OAPOIType *> *)getAllTranslatedNames:(BOOL)skipNonEditable;
- (NSString *) getTranslation:(NSString *)keyName;

+ (UIImage *)getCustomFilterIcon:(OAPOIUIFilter *) filter;

- (BOOL) isNameTag:(NSString *)tag;

@end
