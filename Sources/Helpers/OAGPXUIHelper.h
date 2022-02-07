//
//  OAGPXUIHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAGPXDocument, OATrkSegment;
@class OARouteCalculationResult;
@class OAGPX;

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
                                           time:(float)time
                                preciseLocation:(BOOL)preciseLocation
                                   joinSegments:(BOOL)joinSegments;

+ (CLLocationCoordinate2D)getSegmentPointByDistance:(OATrkSegment *)segment
                                            gpxFile:(OAGPXDocument *)gpxFile
                                    distanceToPoint:(float)distanceToPoint
                                    preciseLocation:(BOOL)preciseLocation
                                       joinSegments:(BOOL)joinSegments;

@end

