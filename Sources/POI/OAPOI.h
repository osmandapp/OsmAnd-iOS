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

#define WEBSITE @"website"
#define PHONE @"phone"
#define MOBILE @"mobile"
#define DESCRIPTION @"description"
#define ROUTE @"route"
#define OPENING_HOURS @"opening_hours"
#define SERVICE_TIMES @"service_times"
#define COLLECTION_TIMES @"collection_times"
#define CONTENT @"content"
#define CUISINE @"cuisine"
#define WIKIDATA @"wikidata"
#define WIKIMEDIA_COMMONS @"wikimedia_commons"
#define MAPILLARY @"mapillary"
#define DISH @"dish"
#define REF @"ref"
#define OSM_DELETE_VALUE @"delete"
#define OSM_DELETE_TAG @"osmand_change"
#define IMAGE_TITLE @"image_title"
#define IS_PART @"is_part"
#define IS_PARENT_OF @"is_parent_of"
#define IS_AGGR_PART @"is_aggr_part"
#define CONTENT_JSON @"content_json"
#define ROUTE_ID @"route_id"
#define ROUTE_SOURCE @"route_source"
#define ROUTE_NAME @"route_name"
#define COLOR @"color"
#define LANG_YES @"lang_yes"
#define GPX_ICON @"gpx_icon"

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

- (UIImage *)icon;
- (NSString *)iconName;

- (BOOL) isClosed;
- (NSSet<NSString *> *)getSupportedContentLocales;
- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;

- (NSDictionary<NSString *, NSString *> *) getAdditionalInfo;

- (NSString *)getContentLanguage:(NSString *)tag lang:(NSString *)lang defLang:(NSString *)defLang;
- (NSString *)getStrictTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getDescription:(NSString *)lang;

@end
