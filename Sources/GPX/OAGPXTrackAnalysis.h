//
//  OAGPXTrackAnalysis.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGpxTrkSeg;
@class OAGpxWpt;
@class OALocationMark;

@interface OASplitMetric : NSObject

-(double) metric:(OALocationMark *)p1 p2:(OALocationMark *)p2;

@end

@interface OADistanceMetric : OASplitMetric
@end

@interface OATimeSplit : OASplitMetric
@end

@interface OASplitSegment : NSObject

@property (nonatomic) OAGpxTrkSeg *segment;
@property (nonatomic, readonly) double startCoeff;
@property (nonatomic, readonly) int startPointInd;
@property (nonatomic, readonly) double endCoeff;
@property (nonatomic, readonly) int endPointInd;
@property (nonatomic) double metricEnd;

- (instancetype)initWithTrackSegment:(OAGpxTrkSeg *)s;
- (instancetype)initWithSplitSegment:(OAGpxTrkSeg *)s pointInd:(int)pointInd cf:(double)cf;

-(int) getNumberOfPoints;

@end


@interface OAGPXTrackAnalysis : NSObject

@property (nonatomic) float totalDistance;
@property (nonatomic) int totalTracks;
@property (nonatomic) long startTime;
@property (nonatomic) long endTime;
@property (nonatomic) long timeSpan;
@property (nonatomic) long timeMoving;
@property (nonatomic) float totalDistanceMoving;

@property (nonatomic) double diffElevationUp;
@property (nonatomic) double diffElevationDown;
@property (nonatomic) double avgElevation;
@property (nonatomic) double minElevation;
@property (nonatomic) double maxElevation;

@property (nonatomic) float maxSpeed;
@property (nonatomic) float avgSpeed;

@property (nonatomic) int points;
@property (nonatomic) int wptPoints;

@property (nonatomic) double metricEnd;
@property (nonatomic) OAGpxWpt *locationStart;
@property (nonatomic) OAGpxWpt *locationEnd;

-(BOOL) isTimeSpecified;
-(BOOL) isTimeMoving;
-(BOOL) isElevationSpecified;
-(int) getTimeHours:(long)time;

-(int) getTimeSeconds:(long)time;
-(int) getTimeMinutes:(long)time;

-(BOOL) isSpeedSpecified;

+(OAGPXTrackAnalysis *) segment:(long)filetimestamp seg:(OAGpxTrkSeg *)seg;
-(void) prepareInformation:(long)fileStamp  splitSegments:(NSArray *)splitSegments;

+(void) splitSegment:(OASplitMetric*)metric metricLimit:(double)metricLimit splitSegments:(NSMutableArray*)splitSegments
             segment:(OAGpxTrkSeg*)segment;
+(NSArray*) convert:(NSArray*)splitSegments;

@end
