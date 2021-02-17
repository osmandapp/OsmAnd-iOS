//
//  OASavingTrackHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAGPXMutableDocument;
@class OAGPX;
@class OAGpxWpt;

@interface OASavingTrackHelper : NSObject

@property (nonatomic, readonly) long lastTimeUpdated;
@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) float distance;
@property (nonatomic, readonly) BOOL isRecording;

@property (nonatomic, readonly) OAGPXMutableDocument *currentTrack;
@property (nonatomic, readonly) NSString *currentTrackPath;

+ (OASavingTrackHelper *)sharedInstance;

- (OAGPX *)getCurrentGPX;

- (BOOL) hasData;
- (BOOL) hasDataToSave;
- (void) clearData;
- (void) saveDataToGpx;
- (void) startNewSegment;
- (BOOL) saveCurrentTrack:(NSString *)fileName;

- (BOOL) saveIfNeeded;

- (void)addWpt:(OAGpxWpt *)wpt;
- (void)deleteWpt:(OAGpxWpt *)wpt;
- (void)deleteAllWpts;
- (void)saveWpt:(OAGpxWpt *)wpt;
- (void)updatePointCoordinates:(OAGpxWpt *)wpt newLocation:(CLLocationCoordinate2D)newLocation;

- (BOOL) getIsRecording;

- (void) runSyncBlock:(void (^)(void))block;

@end
