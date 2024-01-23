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
@class OAGPXDocument;
@class OAGPX;
@class OAWptPt;

@protocol OAUpdatableDelegate <NSObject>

- (void) onNeedUpdateHostData;

@end


@interface OASavingTrackHelper : NSObject

@property (nonatomic, readonly) long lastTimeUpdated;
@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) float distance;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, readonly) int currentTrackIndex;

@property (nonatomic, readonly) OAGPXMutableDocument *currentTrack;

+ (OASavingTrackHelper *)sharedInstance;

- (OAGPX *)getCurrentGPX;

- (BOOL) hasData;
- (BOOL) hasDataToSave;
- (void) clearData;
- (void) saveDataToGpxWithCompletionHandler:(void (^)(void))completionHandler;
- (void) saveDataToGpx;
- (void) startNewSegment;
- (BOOL) saveCurrentTrack:(NSString *)fileName;

- (void)openExportForTrack:(OAGPX *)gpx gpxDoc:(id)gpxDoc isCurrentTrack:(BOOL)isCurrentTrack inViewController:(UIViewController *)hostViewController hostViewControllerDelegate:(id)hostViewControllerDelegate;
- (void) copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OAGPX *)gpx;
- (void) copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OAGPX *)gpx
                        doc:(OAGPXDocument *)doc;

- (void)renameTrack:(OAGPX *)gpx newName:(NSString *)newName hostVC:(UIViewController*)hostVC;
- (void)renameTrack:(OAGPX *)gpx doc:(OAGPXMutableDocument *)doc newName:(NSString *)newName hostVC:(UIViewController*)hostVC;

- (BOOL) saveIfNeeded;

- (void) updateLocation:(CLLocation *)location heading:(CLLocationDirection)heading;

- (void)addWpt:(OAWptPt *)wpt;
- (void)deleteWpt:(OAWptPt *)wpt;
- (void)deleteAllWpts;
- (void)saveWpt:(OAWptPt *)wpt;
- (void)updatePointCoordinates:(OAWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation;

- (BOOL) getIsRecording;

- (void) runSyncBlock:(void (^)(void))block;

@end
