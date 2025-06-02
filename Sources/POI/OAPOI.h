//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAMapObject.h"

static NSString *URL_TAG = @"url";
static NSString *WEBSITE_TAG = @"website";
static NSString *PHONE_TAG = @"phone";
static NSString *MOBILE_TAG = @"mobile";
static NSString *DESCRIPTION_TAG = @"description";
static NSString *ROUTE_TAG = @"route";
static NSString *OPENING_HOURS_TAG = @"opening_hours";
static NSString *SERVICE_TIMES_TAG = @"service_times";
static NSString *COLLECTION_TIMES_TAG = @"collection_times";
static NSString *CONTENT_TAG = @"content";
static NSString *CUISINE_TAG = @"cuisine";
static NSString *WIKIDATA_TAG = @"wikidata";
static NSString *WIKIMEDIA_COMMONS_TAG = @"wikimedia_commons";
static NSString *WIKIPEDIA_TAG = @"wikipedia";
static NSString *MAPILLARY_TAG = @"mapillary";
static NSString *DISH_TAG = @"dish";
static NSString *POI_REF = @"ref";
static NSString *OSM_DELETE_VALUE = @"delete";
static NSString *OSM_DELETE_TAG = @"osmand_change";
static NSString *OSM_ACCESS_PRIVATE_VALUE = @"private";
static NSString *OSM_ACCESS_PRIVATE_TAG = @"access_private";
static NSString *IMAGE_TITLE = @"image_title";
static NSString *IS_PART = @"is_part";
static NSString *IS_PARENT_OF = @"is_parent_of";
static NSString *IS_AGGR_PART = @"is_aggr_part";
static NSString *CONTENT_JSON = @"json";
static NSString *ROUTE_ID = @"route_id";
static NSString *ROUTE_SOURCE = @"route_source";
static NSString *ROUTE_NAME = @"route_name";
static NSString *COLOR_TAG = @"color";
static NSString *LANG_YES = @"lang_yes";
static NSString *GPX_ICON = @"gpx_icon";
static NSString *POITYPE = @"type";
static NSString *SUBTYPE = @"subtype";
static NSString *AMENITY_NAME = @"name";
static NSString *ROUTES = @"routes";
static NSString *ROUTE_ARTICLE = @"route_article";
static NSString *ROUTE_PREFIX = @"routes_";
static NSString *ROUTE_TRACK = @"route_track";
static NSString *ROUTE_TRACK_POINT = @"route_track_point";
static NSString *ROUTE_BBOX_RADIUS = @"route_bbox_radius";
static NSString *ROUTE_MEMBERS_IDS = @"route_members_ids";
static NSString *TRAVEL_EVO_TAG = @"travel_elo";

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

@property (nonatomic) NSMutableDictionary *values;
@property (nonatomic) NSDictionary *localizedContent;

@property (nonatomic) OAPOIRoutePoint *routePoint;
@property (nonatomic) NSString *mapIconName;
@property (nonatomic) NSString *cityName;
@property (nonatomic) NSString *regionName;

- (UIImage *)icon;
- (NSString *)iconName;
- (NSString *)gpxIcon;

- (BOOL) isClosed;
- (BOOL) isPrivateAccess;
- (BOOL) isRouteTrack;
- (BOOL) isRoutePoint;
- (BOOL) isSuperRoute;

- (NSSet<NSString *> *)getSupportedContentLocales;
- (void) updateContentLocales:(NSSet<NSString *> *)locales;

- (NSString *)getName:(NSString *)lang;
- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate;
- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn;

- (NSString *)getEnName:(BOOL)transliterate;

- (NSString *)getGpxFileName:(NSString *)lang;

- (NSDictionary<NSString *, NSString *> *) getAdditionalInfo;
- (NSString *) getAdditionalInfo:(NSString *)key;
- (NSArray<NSString *> *) getAdditionalInfoKeys;

- (void)setAdditionalInfo:(NSDictionary<NSString *, NSString *> *)additionalInfo;
- (void)setAdditionalInfo:(NSString *)tag value:(NSString *)value;
- (void) copyAdditionalInfo:(OAPOI *)amenity overwrite:(BOOL)overwrite;

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

- (NSDictionary<NSString *, NSString *> *) toTagValue:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix;
+ (OAPOI *) fromTagValue:(NSDictionary<NSString *, NSString *> *)map privatePrefix:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix;
- (NSString *)getTagSuffix:(NSString *)tagPrefix;

- (void) setXYPoints:(OARenderedObject *)renderedObject;

- (BOOL) strictEquals:(id)object;

@end
