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
@end
@implementation OAExtraData
@end

@implementation OAGpxWpt
@end
@implementation OAGpxTrk
@end
@implementation OAGpxTrkPt
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