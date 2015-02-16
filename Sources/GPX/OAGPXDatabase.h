//
//  OAGPXDatabase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGpxWpt;
@class OAGPXTrackAnalysis;

@interface OAGPX : NSObject

@property (nonatomic) NSString *gpxFileName;
@property (nonatomic) NSDate *importDate;

// Statistics
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

@end

@interface OAGPXDatabase : NSObject

@property (nonatomic, readonly) NSArray *gpxList;

+ (OAGPXDatabase *)sharedDb;

-(void)addGpxItem:(NSString *)fileName analysis:(OAGPXTrackAnalysis *)analysis;

-(void) load;
-(void) save;

@end
