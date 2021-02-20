//
//  OAGPXDatabase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OACommonTypes.h"

@class OAGPXTrackAnalysis;
@class OAGpxWpt;

@interface OAGPX : NSObject

@property (nonatomic) NSString *gpxFileName;
@property (nonatomic) NSString *gpxFilepath;
@property (nonatomic) NSString *gpxTitle;
@property (nonatomic) NSString *gpxDescription;
@property (nonatomic) NSDate   *importDate;

@property (nonatomic) OAGpxBounds  bounds;
@property (nonatomic, assign) BOOL newGpx;

@property (nonatomic) NSInteger color;
// Statistics
@property (nonatomic) float totalDistance;
@property (nonatomic) int   totalTracks;
@property (nonatomic) long  startTime;
@property (nonatomic) long  endTime;
@property (nonatomic) long  timeSpan;
@property (nonatomic) long  timeMoving;
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

@property (nonatomic) double   metricEnd;
@property (nonatomic) OAGpxWpt *locationStart;
@property (nonatomic) OAGpxWpt *locationEnd;

- (NSString *)getNiceTitle;

@end

@interface OAGPXDatabase : NSObject

@property (nonatomic, readonly) NSArray *gpxList;

+ (OAGPXDatabase *)sharedDb;

-(OAGPX *)buildGpxItem:(NSString *)fileName title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)buildGpxItem:(NSString *)fileName path:(NSString *)filepath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)addGpxItem:(NSString *)fileName title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)addGpxItem:(NSString *)fileName path:(NSString *)filepath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)getGPXItem:(NSString *)fileName;
- (void)replaceGpxItem:(OAGPX *)gpx;
-(void)removeGpxItem:(NSString *)fileName;
-(BOOL)containsGPXItem:(NSString *)fileName;
-(BOOL)updateGPXItemPointsCount:(NSString *)fileName pointsCount:(int)pointsCount;
-(BOOL)updateGPXItemColor:(NSString *)fileName color:(int)color;

-(void) load;
-(void) save;

@end
