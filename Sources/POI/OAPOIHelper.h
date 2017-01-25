//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAResultMatcher.h"
#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>

#define kSearchLimit 200
const static int kSearchRadiusKm[] = {1, 2, 5, 10, 20, 50, 100};

@class OAPOI, OAPOIType, OAPOIBaseType, OAPOICategory, OAPOIFilter;
@class OASearchPoiTypeFilter, OAPOIUIFilter;

@protocol OAPOISearchDelegate

-(void)poiFound:(OAPOI *)poi;
-(void)searchDone:(BOOL)wasInterrupted;

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

@property (nonatomic) OsmAnd::PointI myLocation;

@property (weak, nonatomic) id<OAPOISearchDelegate> delegate;
@property (weak, nonatomic) id<OAPOISearchDelegate> tempDelegate;

+ (OAPOIHelper *)sharedInstance;

- (BOOL)isInit;

- (void)updatePhrases;

- (BOOL) isRegisteredType:(OAPOICategory *)t;
- (NSArray *)poiFiltersForCategory:(NSString *)categoryName;

- (OAPOIType *)getPoiType:(NSString *)tag value:(NSString *)value;
- (OAPOIType *)getPoiTypeByName:(NSString *)name;
- (OAPOIBaseType *)getAnyPoiTypeByName:(NSString *)name;
- (OAPOIType *)getPoiTypeByCategory:(NSString *)category name:(NSString *)name;
- (OAPOIType *)getPoiTypeByKeyInCategory:(OAPOICategory *)category name:(NSString *)name;
- (OAPOIBaseType *)getAnyPoiAdditionalTypeByKey:(NSString *)name;
- (OAPOIType *)getTextPoiAdditionalByKey:(NSString *)name;
- (NSString *)getPoiAdditionalCategoryIcon:(NSString *)category;
- (NSString *)replaceDeprecatedSubtype:(NSString *)subtype;

-(NSString *)getPhraseByName:(NSString *)name;
-(NSString *)getPhraseENByName:(NSString *)name;

-(NSString *)getPoiStringWithoutType:(OAPOI *)poi;

- (OAPOICategory *) getPoiCategoryByName:(NSString *)name;
- (OAPOICategory *) getPoiCategoryByName:(NSString *)name create:(BOOL)create;

- (NSArray<OAPOIBaseType *> *) getTopVisibleFilters;

-(void)setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom;

-(void)findPOIsByKeyword:(NSString *)keyword;
-(void)findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)category poiTypeName:(NSString *)type radiusIndex:(int *)radiusIndex;
-(void)findPOIsByFilter:(OAPOIUIFilter *)filter radiusIndex:(int *)radiusIndex;

+(NSArray<OAPOI *> *)findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radius:(int)radius;
+(NSArray<OAPOI *> *)findPOIsByFilter:(OASearchPoiTypeFilter *)filter topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher;
+(NSArray<OAPOI *> *)findPOIsByName:(NSString *)query topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher;

-(BOOL)breakSearch;

+(OAPOI *)parsePOIByAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity;

+ (void)processLocalizedNames:(QHash<QString, QString>)localizedNames nativeName:(NSString *)nativeName nameLocalized:(NSMutableString *)nameLocalized names:(NSMutableDictionary *)names;
+ (void)processDecodedValues:(QList<OsmAnd::Amenity::DecodedValue>)decodedValues content:(NSMutableDictionary *)content values:(NSMutableDictionary *)values;

@end
