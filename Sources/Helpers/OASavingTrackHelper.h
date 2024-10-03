//
//  OASavingTrackHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kTrackNoHeading -1.0

@class OAGPXMutableDocument;
@class OAGPX;
@class OAWptPt;
@class OASGpxFile, OASWptPt;

@interface OASavingTrackHelper : NSObject

@property (nonatomic, readonly) long lastTimeUpdated;
@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) float distance;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, readonly) int currentTrackIndex;

//@property (nonatomic, readonly) OAGPXMutableDocument *currentTrack;
@property (nonatomic, readonly) OASGpxFile *currentTrackSharedLib;

+ (OASavingTrackHelper *)sharedInstance;

- (OASGpxFile *)getCurrentGPX;

- (OASGpxFile *)getCurrentGPXSharedLib;

- (BOOL) hasData;
- (BOOL) hasDataToSave;
- (void) clearData;
- (void) saveDataToGpxWithCompletionHandler:(void (^)(void))completionHandler;
- (void) saveDataToGpx;
- (void) startNewSegment;
- (BOOL) saveCurrentTrack:(NSString *)fileName;

- (BOOL) saveIfNeeded;

- (void) updateLocation:(CLLocation *)location heading:(CLLocationDirection)heading;

//- (void)addWpt:(OAWptPt *)wpt;
//- (void)deleteWpt:(OAWptPt *)wpt;
//- (void)deleteAllWpts;
//- (void)saveWpt:(OAWptPt *)wpt;
//- (void)updatePointCoordinates:(OAWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation;

- (BOOL) getIsRecording;

- (void) runSyncBlock:(void (^)(void))block;


- (void)addWptNew:(OASWptPt *)wpt;
- (void)deleteWptNew:(OASWptPt *)wpt;
- (void)deleteAllWptsNew;
- (void)saveWptNew:(OASWptPt *)wpt;
- (void)updatePointCoordinatesNew:(OASWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation;

@end
