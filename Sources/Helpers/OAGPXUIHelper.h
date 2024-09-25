//
//  OAGPXUIHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAGPXDocument, OAGPXMutableDocument, OATrkSegment, OARouteCalculationResult, OAGPX, OAGPXTrackAnalysis, OAPOI, OASGpxDataItem;

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

+ (OAGPXDocument *) makeGpxFromRoute:(OARouteCalculationResult *)route;
+ (NSString *) getDescription:(OAGPX *)gpx;

+ (long) getSegmentTime:(OATrkSegment *)segment;
+ (double) getSegmentDistance:(OATrkSegment *)segment;

+ (NSArray<OAGpxFileInfo *> *) getSortedGPXFilesInfo:(NSString *)dir selectedGpxList:(NSArray<NSString *> *)selectedGpxList absolutePath:(BOOL)absolutePath;

+ (void) addAppearanceToGpx:(OAGPXDocument *)gpxFile gpxItem:(OAGPX *)gpxItem;

+ (CLLocationCoordinate2D)getSegmentPointByTime:(OATrkSegment *)segment
                                        gpxFile:(OAGPXDocument *)gpxFile
                                           time:(double)time
                                preciseLocation:(BOOL)preciseLocation
                                   joinSegments:(BOOL)joinSegments;

+ (CLLocationCoordinate2D)getSegmentPointByDistance:(OATrkSegment *)segment
                                            gpxFile:(OAGPXDocument *)gpxFile
                                    distanceToPoint:(double)distanceToPoint
                                    preciseLocation:(BOOL)preciseLocation
                                       joinSegments:(BOOL)joinSegments;

+ (OAPOI *)searchNearestCity:(CLLocationCoordinate2D)latLon;

- (void) openExportForTrack:(OAGPX *)gpx gpxDoc:(id)gpxDoc isCurrentTrack:(BOOL)isCurrentTrack inViewController:(UIViewController *)hostViewController hostViewControllerDelegate:(id)hostViewControllerDelegate touchPointArea:(CGRect)touchPointArea;

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

- (void) renameTrack:(OAGPX *)gpx newName:(NSString *)newName hostVC:(UIViewController*)hostVC;
- (void) renameTrack:(OAGPX *)gpx doc:(OAGPXMutableDocument *)doc newName:(NSString *)newName hostVC:(UIViewController*)hostVC;

- (void)copyNewGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                          gpx:(OASGpxDataItem *)gpx;

- (void)openNewExportForTrack:(OASGpxDataItem *)gpx
            isCurrentTrack:(BOOL)isCurrentTrack
          inViewController:(UIViewController *)hostViewController hostViewControllerDelegate:(id)hostViewControllerDelegate
               touchPointArea:(CGRect)touchPointArea;

- (void)renameTrackNew:(OASGpxDataItem *)gpx
               newName:(NSString *)newName
                hostVC:(UIViewController*)hostVC;

@end

