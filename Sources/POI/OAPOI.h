//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"
#import "OAMapObject.h"

extern NSString * const POI_NAME;

extern NSString * const URL_TAG;
extern NSString * const WEBSITE_TAG;
extern NSString * const PHONE_TAG;
extern NSString * const MOBILE_TAG;
extern NSString * const DESCRIPTION_TAG;
extern NSString * const ROUTE_TAG;
extern NSString * const OPENING_HOURS_TAG;
extern NSString * const SERVICE_TIMES_TAG;
extern NSString * const COLLECTION_TIMES_TAG;
extern NSString * const CONTENT_TAG;
extern NSString * const CUISINE_TAG;
extern NSString * const WIKIDATA_TAG;
extern NSString * const WIKIMEDIA_COMMONS_TAG;
extern NSString * const WIKIPEDIA_TAG;
extern NSString * const MAPILLARY_TAG;
extern NSString * const DISH_TAG;
extern NSString * const POI_REF;
extern NSString * const OSM_DELETE_VALUE;
extern NSString * const OSM_DELETE_TAG;
extern NSString * const OSM_ACCESS_PRIVATE_VALUE;
extern NSString * const OSM_ACCESS_PRIVATE_TAG;
extern NSString * const IMAGE_TITLE;
extern NSString * const IS_PART;
extern NSString * const IS_PARENT_OF;
extern NSString * const IS_AGGR_PART;
extern NSString * const CONTENT_JSON;
extern NSString * const ROUTE_ID;
extern NSString * const ROUTE_SOURCE;
extern NSString * const ROUTE_NAME;
extern NSString * const COLOR_TAG;
extern NSString * const LANG_YES;
extern NSString * const GPX_ICON;
extern NSString * const POITYPE;
extern NSString * const SUBTYPE;
extern NSString * const AMENITY_NAME;
extern NSString * const ROUTES;
extern NSString * const ROUTE_ARTICLE;
extern NSString * const ROUTE_PREFIX;
extern NSString * const ROUTE_TRACK;
extern NSString * const ROUTES_PREFIX;
extern NSString * const ROUTE_TRACK_POINT;
extern NSString * const ROUTE_BBOX_RADIUS;
extern NSString * const ROUTE_MEMBERS_IDS;
extern NSString * const TRAVEL_EVO_TAG;
extern NSString * const COLLAPSABLE_PREFIX;

static int DEFAULT_ELO = 900;


@class OAPOIType, OARenderedObject;

@interface OAPOIRoutePoint : NSObject

@property (nonatomic) double deviateDistance;
@property (nonatomic) BOOL deviationDirectionRight;
@property (nonatomic) CLLocation *pointA;
@property (nonatomic) CLLocation *pointB;

@end

@interface OAPOI : OAMapObject

@property (nonatomic) OAPOIType *type;
@property (nonatomic) NSString *subType;
@property (nonatomic, assign) BOOL hasOpeningHours;
@property (nonatomic) NSString *openingHours;
@property (nonatomic) NSString *desc;
@property (nonatomic) BOOL isPlace;
@property (nonatomic) NSString *buildingNumber;

@property (nonatomic, assign) double distanceMeters;
@property (nonatomic) NSString *distance;
@property (nonatomic, assign) double direction;

@property (nonatomic) MutableOrderedDictionary<NSString *, NSString *> *values;
@property (nonatomic) MutableOrderedDictionary<NSString *, NSString *> *localizedContent;

@property (nonatomic) OAPOIRoutePoint *routePoint;
@property (nonatomic) NSString *mapIconName;
@property (nonatomic) NSString *cityName;
@property (nonatomic) NSString *regionName;

- (UIImage *)icon;
- (NSString *)iconName;
- (NSString *)gpxIcon;

- (BOOL)isClosed;
- (BOOL)isPrivateAccess;
- (BOOL)isRouteTrack;
- (BOOL)isRoutePoint;
- (BOOL)isSuperRoute;

- (NSSet<NSString *> *)getSupportedContentLocales;
- (void)updateContentLocales:(NSSet<NSString *> *)locales;

- (NSString *)getName:(NSString *)lang;
- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate;
- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn;
- (NSDictionary<NSString *, NSString *> *)getAltNamesMap;

- (NSString *)getEnName:(BOOL)transliterate;

- (NSString *)getGpxFileName:(NSString *)lang;

- (MutableOrderedDictionary<NSString *, NSString *> *) getAdditionalInfo;

- (NSString *) getAdditionalInfo:(NSString *)key;
- (NSArray<NSString *> *) getAdditionalInfoKeys;

- (void)setAdditionalInfo:(NSDictionary<NSString *, NSString *> *)additionalInfo;
- (void)setAdditionalInfo:(NSString *)tag value:(NSString *)value;

- (void) copyAdditionalInfo:(OAPOI *)amenity overwrite:(BOOL)overwrite;
- (void) copyAdditionalInfoWithMap:(MutableOrderedDictionary<NSString *,NSString *> *)map overwrite:(BOOL)overwrite;

- (NSString *)getContentLanguage:(NSString *)tag lang:(NSString *)lang defLang:(NSString *)defLang;
- (NSString *)getStrictTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getTagContent:(NSString *)tag;
- (NSString *)getTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getLocalizedContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getDescription:(NSString *)lang;

- (NSString *)getSite;
- (NSString *)getColor;
- (NSString *)getRef;
- (NSString *)getRouteId;
- (NSString *)getWikidata;

- (NSString *)getTravelElo;
- (int)getTravelEloNumber;
- (void)setTravelEloNumber:(int)elo;

- (NSString *) toStringEn;

- (NSString *) getSubTypeStr;

- (NSString *)getRouteActivityType;

- (NSDictionary<NSString *, NSString *> *) toTagValue:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix;
+ (OAPOI *) fromTagValue:(NSDictionary<NSString *, NSString *> *)map privatePrefix:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix;
- (NSString *)getTagSuffix:(NSString *)tagPrefix;

- (void) setXYPoints:(OARenderedObject *)renderedObject;

- (uint64_t) getOsmId;

- (BOOL) strictEquals:(id)object;

@end
