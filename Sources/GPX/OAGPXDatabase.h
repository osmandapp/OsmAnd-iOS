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

@property (nonatomic) NSString *file;
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

-(instancetype)initWithFilePath:(NSString *)filePath title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
- (NSString *)getNiceTitle;

@end

@interface OAGPXDatabase : NSObject

@property (nonatomic, readonly) NSArray *gpxList;

+ (OAGPXDatabase *)sharedDb;

-(OAGPX *)addGpxItem:(NSString *)file title:(NSString *)title desc:(NSString *)desc bounds:(OAGpxBounds)bounds analysis:(OAGPXTrackAnalysis *)analysis;
-(OAGPX *)getGPXItem:(NSString *)file;
-(OAGPX *)getGPXItemByFileName:(NSString *)fileName;
-(void)replaceGpxItem:(OAGPX *)gpx;
-(BOOL)removeGpxItem:(NSString *)file;
-(BOOL)remove:(OAGPX *)item;
-(BOOL)containsGPXItem:(NSString *)file;
-(BOOL)containsGPXItemByFileName:(NSString *)fileName;
-(BOOL)updateGPXItemPointsCount:(NSString *)file pointsCount:(int)pointsCount;
-(BOOL)updateGPXItemColor:(OAGPX *)item color:(int)color;
-(BOOL)updateGPXFolderName:(NSString *)newFilePath oldFilePath:(NSString *)oldFilePath;
-(NSString *)getFileName:(NSString *)itemFile;
-(NSString *)getFileDir:(NSString *)itemFile;

-(NSString *)getGpxStoringPathByFullPath:(NSString *)fullFilePath;

-(void)load;
-(void)save;

@end
