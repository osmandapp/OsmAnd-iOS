//
//  OAGPXDocumentPrimitives.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitives.h"
#import "OAGPXTrackAnalysis.h"

@implementation OAMetadata
@end
@implementation OALink
@end
@implementation OAGpxExtension
@end
@implementation OAGpxExtensions
@end
@implementation OARoute
@end
@implementation OARoutePoint
@end
@implementation OATrack
@end
@implementation OATrackPoint
@end
@implementation OATrackSegment
@end

@implementation OALocationMark

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.elevation = NAN;
    }
    return self;
}

@end

@implementation OAExtraData
@end

@implementation OAGpxWpt

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.satellitesUsedForFixCalculation = -1;
        self.dgpsStationId = -1;
        self.speed = NAN;
        self.magneticVariation = NAN;
        self.geoidHeight = NAN;
        self.fixType = Unknown;
        self.horizontalDilutionOfPrecision = NAN;
        self.verticalDilutionOfPrecision = NAN;
        self.positionDilutionOfPrecision = NAN;
        self.ageOfGpsData = NAN;
    }
    return self;
}

- (void)fillWithWpt:(OAGpxWpt *)gpxWpt
{
    self.wpt = gpxWpt.wpt;
    
    self.position = gpxWpt.position;
    self.name = gpxWpt.name;
    self.desc = gpxWpt.desc;
    self.elevation = gpxWpt.elevation;
    self.time = gpxWpt.time;
    self.comment = gpxWpt.comment;
    self.type = gpxWpt.type;
    
    self.magneticVariation = gpxWpt.magneticVariation;
    self.geoidHeight = gpxWpt.geoidHeight;
    self.source = gpxWpt.source;
    self.symbol = gpxWpt.symbol;
    self.fixType = gpxWpt.fixType;
    self.satellitesUsedForFixCalculation = gpxWpt.satellitesUsedForFixCalculation;
    self.horizontalDilutionOfPrecision = gpxWpt.horizontalDilutionOfPrecision;
    self.verticalDilutionOfPrecision = gpxWpt.verticalDilutionOfPrecision;
    self.positionDilutionOfPrecision = gpxWpt.positionDilutionOfPrecision;
    self.ageOfGpsData = gpxWpt.ageOfGpsData;
    self.dgpsStationId = gpxWpt.dgpsStationId;
    
    self.links = gpxWpt.links;
    self.extraData = gpxWpt.extraData;
}

@end

@implementation OAGpxTrk
@end

@implementation OAGpxTrkPt

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.satellitesUsedForFixCalculation = -1;
        self.dgpsStationId = -1;
        self.speed = NAN;
        self.magneticVariation = NAN;
        self.geoidHeight = NAN;
        self.fixType = Unknown;
        self.horizontalDilutionOfPrecision = NAN;
        self.verticalDilutionOfPrecision = NAN;
        self.positionDilutionOfPrecision = NAN;
        self.ageOfGpsData = NAN;
    }
    return self;
}

@end

@implementation OAGpxTrkSeg

-(NSArray*) splitByDistance:(double)meters
{
    return [self split:[[OADistanceMetric alloc] init] metricLimit:meters];
}

-(NSArray*) splitByTime:(int)seconds
{
    return [self split:[[OATimeSplit alloc] init] metricLimit:seconds];
}

-(NSArray*) split:(OASplitMetric*)metric metricLimit:(double)metricLimit
{
    NSMutableArray *splitSegments = [NSMutableArray array];
    [OAGPXTrackAnalysis splitSegment:metric metricLimit:metricLimit splitSegments:splitSegments segment:self];
    return [OAGPXTrackAnalysis convert:splitSegments];
}


@end

@implementation OAGpxRte
@end
@implementation OAGpxRtePt
@end
@implementation OAGpxLink
@end
@implementation OAGpxMetadata
@end