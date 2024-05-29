//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAPOIType.h"

#define URL_TAG @"url"
#define WEBSITE_TAG @"website"
#define PHONE_TAG @"phone"
#define MOBILE_TAG @"mobile"
#define DESCRIPTION_TAG @"description"
#define ROUTE_TAG @"route"
#define OPENING_HOURS_TAG @"opening_hours"
#define SERVICE_TIMES_TAG @"service_times"
#define COLLECTION_TIMES_TAG @"collection_times"
#define CONTENT_TAG @"content"
#define CUISINE_TAG @"cuisine"
#define WIKIDATA_TAG @"wikidata"
#define WIKIMEDIA_COMMONS_TAG @"wikimedia_commons"
#define WIKIPEDIA_TAG @"wikipedia"
#define MAPILLARY_TAG @"mapillary"
#define DISH_TAG @"dish"
#define POI_REF @"ref"
#define OSM_DELETE_VALUE @"delete"
#define OSM_DELETE_TAG @"osmand_change"
#define IMAGE_TITLE @"image_title"
#define IS_PART @"is_part"
#define IS_PARENT_OF @"is_parent_of"
#define IS_AGGR_PART @"is_aggr_part"
#define CONTENT_JSON @"json"
#define ROUTE_ID @"route_id"
#define ROUTE_SOURCE @"route_source"
#define ROUTE_NAME @"route_name"
#define COLOR_TAG @"color"
#define LANG_YES @"lang_yes"
#define GPX_ICON @"gpx_icon"
#define POITYPE @"type"
#define SUBTYPE @"subtype"
#define AMENITY_NAME @"name"
#define ROUTE_ARTICLE @"route_article"
#define ROUTE_TRACK @"route_track"
#define ROUTE_TRACK_POINT @"route_track_point"

@interface OAPOIRoutePoint : NSObject

@property (nonatomic) double deviateDistance;
@property (nonatomic) BOOL deviationDirectionRight;
@property (nonatomic) CLLocation *pointA;
@property (nonatomic) CLLocation *pointB;

@end

@interface OAPOI : NSObject

@property (nonatomic) unsigned long long obfId;
@property (nonatomic) NSString *name;
@property (nonatomic) OAPOIType *type;
@property (nonatomic) NSString *subType;
@property (nonatomic) NSString *nameLocalized;
@property (nonatomic, assign) BOOL hasOpeningHours;
@property (nonatomic) NSString *openingHours;
@property (nonatomic) NSString *desc;
@property (nonatomic) BOOL isPlace;
@property (nonatomic) NSString *buildingNumber;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic) NSString *distance;
@property (nonatomic, assign) double direction;

@property (nonatomic) NSDictionary *values;
@property (nonatomic) NSDictionary *localizedNames;
@property (nonatomic) NSDictionary *localizedContent;

@property (nonatomic) OAPOIRoutePoint *routePoint;
@property (nonatomic) NSString *mapIconName;

- (UIImage *)icon;
- (NSString *)iconName;
- (NSString *)gpxIcon;

- (BOOL) isClosed;
- (NSSet<NSString *> *)getSupportedContentLocales;
- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate;
- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn;

- (NSDictionary<NSString *, NSString *> *) getAdditionalInfo;

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

- (NSString *) toStringEn;

- (NSDictionary<NSString *, NSString *> *) toTagValue:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix;
+ (OAPOI *) fromTagValue:(NSDictionary<NSString *, NSString *> *)map privatePrefix:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix;
- (NSString *)getTagSuffix:(NSString *)tagPrefix;

@end
