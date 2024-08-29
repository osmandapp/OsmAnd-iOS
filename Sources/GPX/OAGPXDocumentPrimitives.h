//
//  OAGPXDocumentPrimitives.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"

#include <OsmAndCore.h>
#include <OsmAndCore/GpxDocument.h>

#define ICON_NAME_EXTENSION_KEY @"icon"
#define BACKGROUND_TYPE_EXTENSION_KEY @"background"
#define COLOR_NAME_EXTENSION_KEY @"color"
#define ADDRESS_EXTENSION_KEY @"address"
#define CALENDAR_EXTENSION @"calendar_event"
#define PICKUP_DATE @"pickup_date"
#define VISITED_TIME_EXTENSION @"visited_date"
#define CREATION_TIME_EXTENSION @"creation_date"
#define PICKUP_DATE_EXTENSION @"pickup_date"
#define DEFAULT_ICON_NAME_KEY @"special_star"
#define PROFILE_TYPE_EXTENSION_KEY @"profile"

#define PRIVATE_PREFIX @"amenity_"
#define AMENITY_ORIGIN_EXTENSION_KEY @"amenity_origin"
#define OSM_PREFIX_KEY @"osm_tag_"

static NSString * const kGapProfileTypeKey = @"gap";
static NSString * const kTrkptIndexExtension = @"trkpt_idx";

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

struct RouteDataBundle;

@interface OAGPXColor : NSObject

@property (nonatomic) EOAGPXColor type;
@property (nonatomic) NSString *name;
@property (nonatomic) int color;

+ (instancetype)withType:(EOAGPXColor)type name:(NSString *)name color:(int)color;

+ (NSArray<OAGPXColor *> *)values;
+ (OAGPXColor *)getColorFromName:(NSString *)name;

@end

@interface OAGpxExtension : NSObject <NSCopying>

@property (nonatomic) NSString *prefix;
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

- (NSArray<OAGpxExtension *> *) fetchExtension:(QList<OsmAnd::Ref<OsmAnd::GpxExtensions::GpxExtension>>)extensions;
- (void) fetchExtensions:(std::shared_ptr<OsmAnd::GpxExtensions>)extensions;

- (void) fillExtension:(const std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension>&)extension ext:(OAGpxExtension *)e;
- (void) fillExtensions:(const std::shared_ptr<OsmAnd::GpxExtensions>&)extensions;

- (int) getColor:(int)defColor;
- (void) setColor:(int)value;

@end

@interface OALink : OAGpxExtensions

@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *type;

@end

@interface OAAuthor : OAGpxExtensions

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic) OALink *link;

@end

@interface OACopyright : OAGpxExtensions

@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *year;
@property (nonatomic, copy) NSString *license;

@end

// OABounds

@interface OAMetadata : OAGpxExtensions

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray<OALink *> *links;
@property (nonatomic, copy) NSString *keywords;
@property (nonatomic) long time;
@property (nonatomic) OAAuthor *author;
@property (nonatomic) OACopyright *copyright;

@end

@interface OAWptPt : OAGpxExtensions<OALocationPoint>

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;

@property (nonatomic) BOOL firstPoint;
@property (nonatomic) BOOL lastPoint;
@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) CLLocationDistance elevation;
@property (nonatomic) long time;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray<OALink *> *links;
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

+ (OARouteSegment *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;
- (std::shared_ptr<RouteDataBundle>) toStringBundle;

- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (instancetype) initWithRteSegment:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteSegment> &)seg;

- (NSDictionary<NSString *, NSString *> *) toDictionary;

@end

@interface OARouteType : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

+ (OARouteType *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;
- (std::shared_ptr<RouteDataBundle>) toStringBundle;

- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (instancetype) initWithRteType:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteType> &)type;

- (NSDictionary<NSString *, NSString *> *) toDictionary;

@end

@class OASplitMetric;

@interface OATrkSegment : OAGpxExtensions

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::TrkSegment> trkseg;
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

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::Track> trk;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray<OATrkSegment *> *segments;
@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;
@property (nonatomic) BOOL generalTrack;

@end

@interface OARoute : OAGpxExtensions

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::Route> rte;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray<OAWptPt *> *points;
@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;

@end

@interface OAPointsGroup : NSObject

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::PointsGroup> pg;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *backgroundType;
@property (nonatomic) NSArray<OAWptPt *> *points;
@property (nonatomic) UIColor *color;

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name iconName:(NSString *)iconName backgroundType:(NSString *)backgroundType color:(UIColor *)color;
- (instancetype)initWithWptPt:(OAWptPt *)point;
- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;
- (NSDictionary *)toStringBundle;

@end
