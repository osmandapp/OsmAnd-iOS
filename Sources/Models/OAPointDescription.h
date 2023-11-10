//
//  OAPointDescription.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/PointDescription.java
//  git revision e225ad7b03693623bbad7fac3a60700248aee43d

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define POINT_TYPE_FAVORITE @"favorite"
#define POINT_TYPE_WPT @"wpt"
#define POINT_TYPE_GPX @"gpx"
#define POINT_TYPE_RTE @"rte"
#define POINT_TYPE_POI @"poi"
#define POINT_TYPE_ADDRESS @"address"
#define POINT_TYPE_OSM_NOTE "osm_note"
#define POINT_TYPE_MARKER @"marker"
#define POINT_TYPE_PARKING_MARKER @"parking_marker"
#define POINT_TYPE_AUDIO_NOTE @"audionote"
#define POINT_TYPE_VIDEO_NOTE @"videonote"
#define POINT_TYPE_PHOTO_NOTE @"photonote"
#define POINT_TYPE_LOCATION @"location"
#define POINT_TYPE_MY_LOCATION @"my_location"
#define POINT_TYPE_ALARM @"alarm"
#define POINT_TYPE_TARGET @"destination"
#define POINT_TYPE_MAP_MARKER @"map_marker"
#define POINT_TYPE_OSM_BUG @"bug"
#define POINT_TYPE_WORLD_REGION @"world_region"
#define POINT_TYPE_GPX_FILE @"gpx_file"
#define POINT_TYPE_WORLD_REGION_SHOW_ON_MAP @"world_region_show_on_map"
#define POINT_TYPE_BLOCKED_ROAD @"blocked_road"
#define POINT_TYPE_TRANSPORT_ROUTE @"transport_route"
#define POINT_TYPE_TRANSPORT_STOP @"transport_stop"
#define POINT_TYPE_MAPILLARY_IMAGE @"mapillary_image"
#define POINT_TYPE_POI_TYPE @"poi_type"
#define POINT_TYPE_CUSTOM_POI_FILTER @"custom_poi_filter"

#define POINT_LOCATION_URL 200
#define OSM_LOCATION_URL 210
#define POINT_LOCATION_LIST_HEADER 201

@protocol OALocationPoint;

@interface OAPointDescription : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *typeName;
@property (nonatomic) NSString *iconName;

@property (nonatomic, readonly) NSString *type;

@property (nonatomic, readonly) double lat;
@property (nonatomic, readonly) double lon;


- (instancetype)initWithLatitude:(double)lat longitude:(double)lon;
- (instancetype)initWithType:(NSString *)type name:(NSString *)name;
- (instancetype)initWithType:(NSString *)type typeName:(NSString *)typeName name:(NSString *)name;

+ (NSString *) serializeToString:(OAPointDescription *)p;
+ (OAPointDescription *) deserializeFromString:(NSString *)s l:(CLLocation *)l;

- (NSString *) getSimpleName:(BOOL)addTypeName;
+ (NSString *) getLocationName:(double)lat lon:(double)lon sh:(BOOL)sh;
+ (NSString *) getLocationNamePlain:(double)lat lon:(double)lon;
+ (NSString *) getSimpleName:(id<OALocationPoint>)o;
+ (NSString *) getSearchAddressStr;
+ (NSString *) getAddressNotFoundStr;
- (BOOL) isSearchingAddress;

+ (NSDictionary <NSNumber *, NSString *> *) getLocationData:(double) lat lon:(double)lon;
+ (NSString *) formatToHumanString:(NSInteger)format;
+ (NSInteger) coordinatesFormatToFormatterMode:(NSInteger)format;

- (BOOL) isLocation;
- (BOOL) isAddress;
- (BOOL) isWpt;
- (BOOL) isPoi;
- (BOOL) isFavorite;
- (BOOL) isAudioNote;
- (BOOL) isVideoNote;
- (BOOL) isPhotoNote;
- (BOOL) isDestination;
- (BOOL) isMapMarker;
- (BOOL) isParking;
- (BOOL) isMyLocation;
- (BOOL) isPoiType;
- (BOOL) isCustomPoiFilter;
- (BOOL) isGpxPoint;
- (BOOL) isGpxFile;

@end
