//
//  OAPointDescription.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/PointDescription.java
//  git revision e5a489637a08d21827a1edd2cf6581339b5f748a

#import <Foundation/Foundation.h>

#define POINT_TYPE_FAVORITE @"favorite"
#define POINT_TYPE_WPT @"wpt"
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
#define POINT_TYPE_GPX_ITEM @"gpx_item"
#define POINT_TYPE_WORLD_REGION_SHOW_ON_MAP @"world_region_show_on_map"
#define POINT_TYPE_BLOCKED_ROAD @"blocked_road"
#define POINT_TYPE_TRANSPORT_ROUTE @"transport_route"
#define POINT_TYPE_TRANSPORT_STOP @"transport_stop"
#define POINT_TYPE_MAPILLARY_IMAGE @"mapillary_image"

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

- (NSString *) getSimpleName:(BOOL)addTypeName;
+ (NSString *) getLocationName:(double)lat lon:(double)lon sh:(BOOL)sh;
+ (NSString *) getSimpleName:(id<OALocationPoint>)o;
+ (NSString *) getSearchAddressStr;
+ (NSString *) getAddressNotFoundStr;

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

@end
