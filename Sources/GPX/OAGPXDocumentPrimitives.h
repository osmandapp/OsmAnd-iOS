//
//  OAGPXDocumentPrimitives.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OALocationPoint.h"

#define ICON_NAME_EXTENSION @"icon"
#define BACKGROUND_TYPE_EXTENSION @"background"
#define ADDRESS_EXTENSION @"address"
#define CALENDAR_EXTENSION @"calendar_event"
#define PICKUP_DATE @"pickup_date"
#define VISITED_TIME_EXTENSION @"visited_date"
#define CREATION_TIME_EXTENSION @"creation_date"
#define PICKUP_DATE_EXTENSION @"pickup_date"
#define DEFAULT_ICON_NAME @"special_star"
#define PROFILE_TYPE_EXTENSION @"profile"
#define GAP_PROFILE_TYPE @"gap"
#define TRKPT_INDEX_EXTENSION @"trkpt_idx"
#define PRIVATE_PREFIX @"amenity_"
#define AMENITY_ORIGIN_EXTENSION @"amenity_origin"
#define OSM_PREFIX @"osm_tag_"

typedef NS_ENUM(NSInteger, EOAGPXColor)
{
    BLACK = 0,
    DARKGRAY,
    GRAY,
    LIGHTGRAY,
    WHITE,
    RED,
    GREEN,
    DARKGREEN,
    BLUE,
    YELLOW,
    CYAN,
    MAGENTA,
    AQUA,
    FUCHSIA,
    DARKGREY,
    GREY,
    LIGHTGREY,
    LIME,
    MAROON,
    NAVY,
    OLIVE,
    PURPLE,
    SILVER,
    TEAL
};

@class OAPOI;

@interface OAGPXColor : NSObject

@property (nonatomic) EOAGPXColor type;
@property (nonatomic) NSString *name;
@property (nonatomic) int color;

+ (instancetype)withType:(EOAGPXColor)type name:(NSString *)name color:(int)color;

+ (NSArray<OAGPXColor *> *)values;
+ (OAGPXColor *)getColorFromName:(NSString *)name;

@end

@interface OAGpxExtension : NSObject <NSCopying>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *value;
@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSArray *subextensions;

@end

@interface OAGpxExtensions : NSObject

@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSString *value;
@property (nonatomic) NSArray<OAGpxExtension *> *extensions;

- (void) copyExtensions:(OAGpxExtensions *)e;
- (OAGpxExtension *) getExtensionByKey:(NSString *)key;
- (void) addExtension:(OAGpxExtension *)e;
- (void) removeExtension:(OAGpxExtension *)e;
- (void) setExtension:(NSString *)key value:(NSString *)value;

- (int) getColor:(int)defColor;
- (void) setColor:(int)value;

@end

@interface OALink : OAGpxExtensions

@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *type;

@end

// OAAuthor
// OACopyright
// OABounds

@interface OAMetadata : OAGpxExtensions

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray *links;
@property (nonatomic) long time;

@end

@interface OAWptPt : OAGpxExtensions<OALocationPoint>

@property (nonatomic) BOOL firstPoint;
@property (nonatomic) BOOL lastPoint;
@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) CLLocationDistance elevation;
@property (nonatomic) long time;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *links;
@property (nonatomic) double distance;
@property (nonatomic) double speed;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double heading;

- (instancetype)initWithWpt:(OAWptPt *)wptPt;

- (NSString *)getIcon;
- (void)setIcon:(NSString *)iconName;
- (NSString *)getBackgroundIcon;
- (void)setBackgroundIcon:(NSString *)backgroundIconName;
- (NSString *)getAddress;

- (NSString *) getProfileType;
- (void) setProfileType:(NSString *)profileType;
- (void) removeProfileType;
- (BOOL) hasProfile;
- (BOOL) isGap;
- (void) setGap;

- (NSInteger) getTrkPtIndex;
- (void) setTrkPtIndex:(NSInteger)index;

- (OAPOI *) getAmenity;
- (void) setAmenity:(OAPOI *)amenity;

- (NSString *) getAmenityOriginName;
- (void) setAmenityOriginName:(NSString *)originName;

@end

@interface OARouteSegment : NSObject

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *length;
@property (nonatomic) NSString *startTrackPointIndex;
@property (nonatomic) NSString *segmentTime;
@property (nonatomic) NSString *speed;
@property (nonatomic) NSString *turnType;
@property (nonatomic) NSString *turnAngle;
@property (nonatomic) NSString *types;
@property (nonatomic) NSString *pointTypes;
@property (nonatomic) NSString *names;

@end

@interface OARouteType : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

@end

@class OASplitMetric;

@interface OATrkSegment : OAGpxExtensions

@property (nonatomic) BOOL generalSegment;

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray<OAWptPt *> *points;

@property (nonatomic) NSMutableArray<OARouteSegment *> *routeSegments;
@property (nonatomic) NSMutableArray<OARouteType *> *routeTypes;

-(NSArray *) splitByDistance:(double)meters joinSegments:(BOOL)joinSegments;
-(NSArray *) splitByTime:(int)seconds joinSegments:(BOOL)joinSegments;
-(NSArray *) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(double)metricLimit joinSegments:(BOOL)joinSegments;

- (BOOL) hasRoute;

- (void) fillExtensions;
- (void) fillRouteDetails;

@end

@interface OATrack : OAGpxExtensions

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray<OATrkSegment *> *segments;
@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;
@property (nonatomic) BOOL generalTrack;

@end

@interface OARoute : OAGpxExtensions

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray<OAWptPt *> *points;
@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;

@end
