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

@class OASGpxFile, OASWptPt, TrackRecordingSnapshot;

@interface OASavingTrackHelper : NSObject

@property (nonatomic, readonly) long lastTimeUpdated;
@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) float distance;
@property (nonatomic, readonly) BOOL isRecording;
@property (atomic, readonly) int currentTrackIndex;
@property (atomic, copy, readonly) NSString *currentTrackIdentifier;
@property (atomic, readonly) BOOL hasTrackPoints;

@property (nonatomic, readonly) OASGpxFile *currentTrack;

+ (OASavingTrackHelper *)sharedInstance;

- (BOOL) hasData;
- (BOOL) hasDataToSave;
- (void)clearData;
- (void) saveDataToGpxWithCompletionHandler:(void (^)(void))completionHandler;
- (void) saveDataToGpx;
- (void) startNewSegment;
- (BOOL) saveCurrentTrack:(NSString *)fileName;
- (BOOL) saveIfNeeded;
- (void) updateLocation:(CLLocation *)location heading:(CLLocationDirection)heading;
- (BOOL) getIsRecording;

// Copies recording values and calls completion on the recording queue.
- (void)readTrackRecordingSnapshotWithCompletion:(void (^ _Nonnull)(TrackRecordingSnapshot * _Nonnull snapshot))completion;

- (void) runSyncBlock:(void (^)(void))block;

- (void)addWpt:(OASWptPt *)wpt;
- (BOOL)deleteWpt:(OASWptPt *)wpt;
- (BOOL)deleteWpts:(NSArray<OASWptPt *> *)waypoints;
- (void)deleteAllWpts;
- (BOOL)saveWpt:(OASWptPt *)wpt;
- (void)saveWpts:(NSArray<OASWptPt *> *)waypoints completion:(void (^)(BOOL saved))completion;
- (BOOL)updatePointCoordinates:(OASWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation;
- (BOOL)updatePointCoordinates:(OASWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation removingPoint:(OASWptPt *)removedPoint;

@end
