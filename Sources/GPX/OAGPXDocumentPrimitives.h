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

#define ICON_NAME_EXTENSION @"icon"
#define BACKGROUND_TYPE_EXTENSION @"background"
#define ADDRESS_EXTENSION @"address"
#define CALENDAR_EXTENSION @"calendar_event"
#define CREATION_TIME_EXTENSION @"creation_date"

typedef enum
{
    Unknown = -1,
    None,
    PositionOnly,
    PositionAndElevation,
    DGPS,
    PPS
    
} OAGpxFixType;

struct RouteDataBundle;
@class OAGpxExtension;

@interface OARouteSegment : NSObject

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *length;
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
- (instancetype) initWithGpxExtension:(OAGpxExtension *)ext;

- (NSDictionary<NSString *, NSString *> *) toDictionary;

@end

@interface OARouteType : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

+ (OARouteType *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;
- (std::shared_ptr<RouteDataBundle>) toStringBundle;

- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (instancetype) initWithGpxExtension:(OAGpxExtension *)ext;

- (NSDictionary<NSString *, NSString *> *) toDictionary;

@end


@interface OAExtraData : NSObject
@end

@interface OALink : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *text;

@end

@interface OAMetadata : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSArray *links;
@property (nonatomic) long time;
@property (nonatomic) OAExtraData *extraData;

@end

@interface OALocationMark : NSObject<OALocationPoint>

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
@property (nonatomic) OAExtraData *extraData;
@property (nonatomic) double distance;

@end

@interface OATrackPoint : OALocationMark

@end

@class OAGpxTrkPt;

@interface OATrackSegment : NSObject

@property (nonatomic) NSArray<OAGpxTrkPt *> *points;
@property (nonatomic) OAExtraData *extraData;

@end

@class OAGpxTrkSeg;

@interface OATrack : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSArray<OAGpxTrkSeg *> *segments;
@property (nonatomic) OAExtraData *extraData;

@end

@interface OARoutePoint : OALocationMark

@end

@class OAGpxRtePt;

@interface OARoute : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSArray<OAGpxRtePt *> *points;
@property (nonatomic) OAExtraData *extraData;

@end

// TODO: Sync code with Android (get rid of OAGpxExtension)

@interface OAGpxExtension : OAExtraData

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *value;
@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSArray *subextensions;

@end

@interface OAGpxExtensions : OAExtraData

// TODO: Sync with Android
@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSString *value;
@property (nonatomic) NSArray<OAGpxExtension *> *extensions;

- (void) copyExtensions:(OAGpxExtensions *)e;

@end

@interface OAGpxLink : OALink

@property (nonatomic) NSString *type;

@end

@interface OAGpxMetadata : OAMetadata

@end

@interface OAGpxWpt : OALocationMark

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> wpt;

@property (nonatomic) NSString *color;
@property (nonatomic) double speed;
@property (nonatomic) double magneticVariation;
@property (nonatomic) double geoidHeight;
@property (nonatomic) NSString *source;
@property (nonatomic) NSString *symbol;
@property (nonatomic) OAGpxFixType fixType;
@property (nonatomic) int satellitesUsedForFixCalculation;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double positionDilutionOfPrecision;
@property (nonatomic) double ageOfGpsData;
@property (nonatomic) int dgpsStationId;
@property (nonatomic) NSString *profileType;

- (void) fillWithWpt:(OAGpxWpt *)gpxWpt;
- (void) fillWithTrkPt:(OAGpxTrkPt *)gpxWpt;

- (OAGpxExtension *)getExtensionByKey:(NSString *)key;
- (void)setExtension:(NSString *)key value:(NSString *)value;

- (NSString *)getIcon;
- (NSString *)getBackgroundIcon;
- (NSString *)getAddress;

@end

@interface OAGpxTrkPt : OATrackPoint

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::GpxTrkPt> trkpt;

@property (nonatomic) double speed;
@property (nonatomic) double magneticVariation;
@property (nonatomic) double geoidHeight;
@property (nonatomic) NSString *source;
@property (nonatomic) NSString *symbol;
@property (nonatomic) OAGpxFixType fixType;
@property (nonatomic) int satellitesUsedForFixCalculation;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double positionDilutionOfPrecision;
@property (nonatomic) double ageOfGpsData;
@property (nonatomic) int dgpsStationId;

- (instancetype) initWithPoint:(OAGpxTrkPt *)point;
- (instancetype) initWithRtePt:(OAGpxRtePt *)point;

- (NSString *) getProfileType;
- (void) setProfileType:(NSString *)profileType;
- (void) removeProfileType;
- (BOOL) hasProfile;
- (BOOL) isGap;
- (void) setGap;
- (void) copyExtensions:(OAGpxTrkPt *)pt;

- (NSInteger) getTrkPtIndex;
- (void) setTrkPtIndex:(NSInteger)index;

@end

@class OASplitMetric;

@interface OAGpxTrkSeg : OATrackSegment

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;
@property (nonatomic) BOOL generalSegment;

@property (nonatomic) NSMutableArray<OARouteSegment *> *routeSegments;
@property (nonatomic) NSMutableArray<OARouteType *> *routeTypes;

-(NSArray*) splitByDistance:(double)meters joinSegments:(BOOL)joinSegments;
-(NSArray*) splitByTime:(int)seconds joinSegments:(BOOL)joinSegments;
-(NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(double)metricLimit joinSegments:(BOOL)joinSegments;

- (BOOL) hasRoute;

- (void) fillExtensions;
- (void) fillRouteDetails;

@end

@interface OAGpxTrk : OATrack

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::GpxTrk> trk;

@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;
@property (nonatomic) BOOL generalTrack;

@end

@interface OAGpxRtePt : OARoutePoint

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::GpxRtePt> rtept;

@property (nonatomic) double speed;
@property (nonatomic) double magneticVariation;
@property (nonatomic) double geoidHeight;
@property (nonatomic) NSString *source;
@property (nonatomic) NSString *symbol;
@property (nonatomic) OAGpxFixType fixType;
@property (nonatomic) int satellitesUsedForFixCalculation;
@property (nonatomic) double horizontalDilutionOfPrecision;
@property (nonatomic) double verticalDilutionOfPrecision;
@property (nonatomic) double positionDilutionOfPrecision;
@property (nonatomic) double ageOfGpsData;
@property (nonatomic) int dgpsStationId;

- (instancetype) initWithTrkPt:(OAGpxTrkPt *)point;

@end

@interface OAGpxRte : OARoute

@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::GpxRte> rte;

@property (nonatomic) NSString *source;
@property (nonatomic) int slotNumber;

@end

@interface OAGpxRouteSegment : NSObject

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *length;
@property (nonatomic) NSString *segmentTime;
@property (nonatomic) NSString *speed;
@property (nonatomic) NSString *turnType;
@property (nonatomic) NSString *turnAngle;
@property (nonatomic) NSString *types;
@property (nonatomic) NSString *pointTypes;
@property (nonatomic) NSString *names;

- (instancetype) init;
+ (OAGpxRouteSegment *) fromStringBundle:(NSDictionary<NSString *, NSString *> *)bundle;
- (NSDictionary<NSString *, NSString *> *) toStringBundle;

@end

@interface OAGpxRouteType : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

- (instancetype) init;
+ (OAGpxRouteType *) fromStringBundle:(NSDictionary<NSString *, NSString *> *)bundle;
- (NSDictionary<NSString *, NSString *> *) toStringBundle;

@end
