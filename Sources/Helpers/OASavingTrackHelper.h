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

@class OASGpxFile, OASWptPt;

@interface OASavingTrackHelper : NSObject

@property (nonatomic, readonly) long lastTimeUpdated;
@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) float distance;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, readonly) int currentTrackIndex;

@property (nonatomic, readonly) OASGpxFile *currentTrack;

+ (OASavingTrackHelper *)sharedInstance;

- (BOOL) hasData;
- (BOOL) hasDataToSave;
- (void) clearData;
- (void) saveDataToGpxWithCompletionHandler:(void (^)(void))completionHandler;
- (void) saveDataToGpx;
- (void) startNewSegment;
- (BOOL) saveCurrentTrack:(NSString *)fileName;
- (BOOL) saveIfNeeded;
- (void) updateLocation:(CLLocation *)location heading:(CLLocationDirection)heading;
- (BOOL) getIsRecording;

- (void) runSyncBlock:(void (^)(void))block;

- (void)addWpt:(OASWptPt *)wpt;
- (void)deleteWpt:(OASWptPt *)wpt;
- (void)deleteAllWpts;
- (void)saveWpt:(OASWptPt *)wpt;
- (void)updatePointCoordinates:(OASWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation;

@end
