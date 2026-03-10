//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OSM_WIKI_CATEGORY;
extern NSString * const SPEED_CAMERA ;
extern NSString * const WIKI_LANG;
extern NSString * const WIKI_PLACE;
extern NSString * const ROUTE_ARTICLE_POINT;

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

+ (nonnull OAPOIHelper *) sharedInstance;

- (BOOL) isInit;

- (void) updatePhrases;

- (BOOL) isRegisteredType:(OAPOICategory *)t;
- (NSArray *) poiFiltersForCategory:(NSString *)categoryName;

- (OAPOIType *) getPoiType:(NSString *)tag value:(NSString *)value;
- (OAPOIType *) getPoiTypeByName:(NSString *)name;
- (nullable OAPOIType *) getPoiTypeByKey:(NSString *)name;
- (OAPOIType *) getAnyPoiTypeByKey:(NSString *)name;
- (OAPOIBaseType *) getAnyPoiTypeByName:(NSString *)name;
- (OAPOIType *) getPoiTypeByCategory:(NSString *)category name:(NSString *)name;
- (OAPOIType *) getPoiTypeByKeyInCategory:(OAPOICategory *)category name:(NSString *)name;
- (OAPOIBaseType *) getAnyPoiAdditionalTypeByKey:(NSString *)name;
- (OAPOIType *) getTextPoiAdditionalByKey:(NSString *)name;
- (nullable OAPOIType *) getPoiAdditionalType:(nullable OAPOICategory *)category name:(NSString *)name;
- (NSString *) getPoiTypeOptionalIcon:(NSString *)type;
- (nullable NSString *) getPoiAdditionalCategoryIcon:(nullable NSString *)category;
- (NSString *) replaceDeprecatedSubtype:(NSString *)subtype;

- (nullable NSString *) getPhraseByName:(NSString *)name;
- (nullable NSString *) getPhraseByName:(NSString *)name withDefatultValue:(BOOL)withDefatultValue;
- (NSString *) getPhraseENByName:(NSString *)name;
- (NSString *) getSynonymsByName:(NSString *)name;
- (NSString *) getPhrase:(OAPOIBaseType *)type;
- (NSString *) getPhraseEN:(OAPOIBaseType *)type;

- (NSString *)getPoiStringWithoutType:(OAPOI *)poi;
- (NSString *)getFormattedOpeningHours:(OAPOI *)poi;
- (NSString *)getAmenityDistanceFormatted:(OAPOI *)amenity;

- (NSArray<OAPOICategory *> *) getCategories:(BOOL)includeMapCategory;
- (OAPOICategory *) getPoiCategoryByName:(NSString *)name;
- (OAPOICategory *) getPoiCategoryByName:(NSString *)name create:(BOOL)create;

- (NSArray<OAPOIBaseType *> *) getTopVisibleFilters;
- (OAPOICategory *) getOsmwiki;
- (NSArray<NSString *> *)getAllAvailableWikiLocales;
- (NSString *) getAllLanguagesTranslationSuffix;

- (OAPOIType *) getDefaultOtherCategoryType;
- (NSMutableArray<NSString *> *) getPublicTransportTypes;

- (NSDictionary<NSString *, OAPOIType *> *)getAllTranslatedNames:(BOOL)skipNonEditable;
- (nullable NSString *) getTranslation:(nullable NSString *)keyName;

+ (UIImage *)getCustomFilterIcon:(OAPOIUIFilter *) filter;

- (BOOL) isNameTag:(NSString *)tag;

@end

NS_ASSUME_NONNULL_END
