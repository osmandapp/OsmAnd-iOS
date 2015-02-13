//
//  OAGPXTrackAnalysis.h
//  OsmAnd
//
//  Created by Admin on 13/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDocument.h"

@interface OASplitSegment : NSObject

@property (nonatomic) OATrackSegment *segment;
@property (nonatomic, readonly) double startCoeff;
@property (nonatomic, readonly) int startPointInd;
@property (nonatomic, readonly) double endCoeff;
@property (nonatomic, readonly) int endPointInd;
@property (nonatomic, readonly) double metricEnd;

- (instancetype)initWithTrackSegment:(OATrackSegment *)s;
- (instancetype)initWithSplitSegment:(OATrackSegment *)s pointInd:(int)pointInd cf:(double)cf;

-(int) getNumberOfPoints;

@end

@interface OAGPXTrackAnalysis : NSObject

@property (nonatomic, readonly) float totalDistance;
@property (nonatomic, readonly) int totalTracks;
@property (nonatomic, readonly) long startTime;
@property (nonatomic, readonly) long endTime;
@property (nonatomic, readonly) long timeSpan;
@property (nonatomic, readonly) long timeMoving;
@property (nonatomic, readonly) float totalDistanceMoving;

@property (nonatomic, readonly) double diffElevationUp;
@property (nonatomic, readonly) double diffElevationDown;
@property (nonatomic, readonly) double avgElevation;
@property (nonatomic, readonly) double minElevation;
@property (nonatomic, readonly) double maxElevation;

@property (nonatomic, readonly) float maxSpeed;
@property (nonatomic, readonly) float avgSpeed;

@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) int wptPoints;

@property (nonatomic, readonly) double metricEnd;
@property (nonatomic) OAGpxWpt *locationStart;
@property (nonatomic) OAGpxWpt *locationEnd;

-(BOOL) isTimeSpecified;
-(BOOL) isTimeMoving;
-(BOOL) isElevationSpecified;
-(int) getTimeHours:(long)time;

-(int) getTimeSeconds:(long)time;
-(int) getTimeMinutes:(long)time;

-(BOOL) isSpeedSpecified;

+(OAGPXTrackAnalysis *) segment:(long)filetimestamp seg:(OATrackSegment *)seg;

@end
