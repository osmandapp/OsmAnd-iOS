//
//  OAGPXUIHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OARouteCalculationResult, OAPOI;
@class OASTrkSegment, OASGpxFile, OASTrack, OASGpxTrackAnalysis, OASGpxDataItem, OASTrackItem;

@protocol OATrackSavingHelperUpdatableDelegate <NSObject>

- (void) onNeedUpdateHostData;

@end

@interface OAGpxFileInfo : NSObject

@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) long lastModified;
@property (nonatomic, readonly) long fileSize;
@property (nonatomic) BOOL selected;

- (instancetype) initWithFileName:(NSString *)fileName lastModified:(long)lastModified fileSize:(long)fileSize;

@end

@interface OAGPXUIHelper : NSObject

+ (OASGpxFile *) makeGpxFromRoute:(OARouteCalculationResult *)route;
+ (NSString *) getDescription:(OASGpxDataItem *)gpx;

+ (long) getSegmentTime:(OASTrkSegment *)segment;
+ (double) getSegmentDistance:(OASTrkSegment *)segment;

+ (NSArray<OAGpxFileInfo *> *) getSortedGPXFilesInfo:(NSString *)dir selectedGpxList:(NSArray<NSString *> *)selectedGpxList absolutePath:(BOOL)absolutePath;

+ (void) addAppearanceToGpx:(OASGpxFile *)gpxFile gpxItem:(OASGpxDataItem *)gpxItem;

+ (CLLocationCoordinate2D)getSegmentPointByTime:(OASTrkSegment *)segment
                                        gpxFile:(OASGpxFile *)gpxFile
                                           time:(double)time
                                preciseLocation:(BOOL)preciseLocation
                                   joinSegments:(BOOL)joinSegments;

+ (CLLocationCoordinate2D)getSegmentPointByDistance:(OASTrkSegment *)segment
                                            gpxFile:(OASGpxFile *)gpxFile
                                    distanceToPoint:(double)distanceToPoint
                                    preciseLocation:(BOOL)preciseLocation
                                       joinSegments:(BOOL)joinSegments;

+ (OAPOI *)searchNearestCity:(CLLocationCoordinate2D)latLon;

- (void) openExportForTrack:(OASGpxDataItem *)gpx gpxDoc:(id)gpxDoc isCurrentTrack:(BOOL)isCurrentTrack inViewController:(UIViewController *)hostViewController hostViewControllerDelegate:(id)hostViewControllerDelegate touchPointArea:(CGRect)touchPointArea;

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       trackItem:(OASTrackItem *)trackItem;

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                 trackItem:(OASTrackItem *)trackItem
                   gpxFile:(OASGpxFile *)gpxFile
  updatedTrackItemСallback:(void (^_Nullable)(OASTrackItem *updatedTrackItem))updatedTrackItemСallback;

- (void) renameTrack:(OASGpxDataItem *)gpx newName:(NSString *)newName hostVC:(UIViewController*)hostVC;
- (void) renameTrack:(OASGpxDataItem *)gpx doc:(OASGpxFile *)doc newName:(NSString *)newName hostVC:(UIViewController*)hostVC updatedTrackItemСallback:(void (^_Nullable)(OASTrackItem *updatedTrackItem))updatedTrackItemСallback;;

+ (NSString *)buildTrackSegmentName:(OASGpxFile *)gpxFile
                              track:(OASTrack *)track
                            segment:(OASTrkSegment *)segment;

+ (NSString *)getGPXStatisticStringForGpxDataItem:(OASGpxDataItem *)dataItem showLastModifiedTime:(BOOL)showLastModifiedTime;
+ (NSString *)getGPXStatisticStringFor:(nullable NSDate *)lastModifiedTime
                         totalDistance:(float)totalDistance
                              timeSpan:(NSInteger)timeSpan
                             wptPoints:(int)wptPoints;


@end

