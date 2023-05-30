//
//  OAGPXDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDocumentPrimitives.h"
#import "OACommonTypes.h"

@class OAGPXTrackAnalysis, OASplitMetric, QuadRect, OAApplicationMode, OAGPXDocumentNativeWrapper;

@interface OAGPXDocument : OAGpxExtensions

@property (nonatomic) OAMetadata* metadata;
@property (nonatomic) NSArray<OAWptPt *> *points;
@property (nonatomic) NSArray<OATrack *> *tracks;
@property (nonatomic) NSArray<OARoute *> *routes;

@property (nonatomic) NSArray<OARouteSegment *> *routeSegments;
@property (nonatomic) NSArray<OARouteType *> *routeTypes;

@property (nonatomic) NSDictionary<NSString *, NSString *> *networkRouteKeyTags;

@property (nonatomic) OAGpxBounds bounds;

@property (nonatomic) BOOL hasAltitude;

@property (nonatomic) NSString *version;
@property (nonatomic) NSString *creator;

@property (nonatomic, copy) NSString *path;

@property (nonatomic) OATrack *generalTrack;
@property (nonatomic) OATrkSegment *generalSegment;

@property (nonatomic) OAGPXDocumentNativeWrapper *wrapper;

- (instancetype)initWithNativeWrapper:(OAGPXDocumentNativeWrapper *)wrapper;
- (instancetype)initWithGpxFile:(NSString *)filename;

- (BOOL) loadFrom:(NSString *)filename;
- (BOOL) fetch:(NSString *)fileName;

- (BOOL) saveTo:(NSString *)filename;

- (BOOL) isCloudmadeRouteFile;

- (void) processPoints;
- (NSArray<OATrkSegment *> *) getPointsToDisplay;

- (BOOL) isEmpty;
- (void) addGeneralTrack;
- (OAWptPt *) findPointToShow;
- (BOOL) hasRtePt;
- (BOOL) hasWptPt;
- (BOOL) hasTrkPt;
- (BOOL) hasRoute;
- (BOOL) isRoutesPoints;

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp;

- (NSArray*) splitByDistance:(int)meters joinSegments:(BOOL)joinSegments;
- (NSArray*) splitByTime:(int)seconds joinSegments:(BOOL)joinSegments;
- (NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(int)metricLimit joinSegments:(BOOL)joinSegments;

- (NSArray<OAWptPt *> *) getRoutePoints;
- (NSArray<OAWptPt *> *) getRoutePoints:(NSInteger)routeIndex;
- (OAApplicationMode *) getRouteProfile;
- (NSArray<OATrack *> *) getTracks:(BOOL)includeGeneralTrack;

- (void)initBounds;
- (void)processBounds:(CLLocationCoordinate2D)coord;
- (void)applyBounds;

- (double) getSpeed:(NSArray<OAGpxExtension *> *)extensions;

+ (NSString *)buildTrackSegmentName:(OAGPXDocument *)gpxFile
                              track:(OATrack *)track
                            segment:(OATrkSegment *)segment;
- (NSString *) getColoringType;
- (NSString *) getGradientScaleType;
- (void) setColoringType:(NSString *)coloringType;
- (void) removeGradientScaleType;
- (NSString *) getSplitType;
- (void) setSplitType:(NSString *)gpxSplitType;
- (double) getSplitInterval;
- (void) setSplitInterval:(double)splitInterval;
- (NSString *) getWidth:(NSString *)defWidth;
- (void) setWidth:(NSString *)width;
- (BOOL) isShowArrows;
- (void) setShowArrows:(BOOL)showArrows;
- (BOOL) isShowStartFinish;
- (void) setShowStartFinish:(BOOL)showStartFinish;

- (OATrack *) getGeneralTrack;
- (OATrkSegment *) getGeneralSegment;
- (NSArray<OATrkSegment *> *)getNonEmptyTrkSegments:(BOOL)routesOnly;
- (NSInteger) getNonEmptySegmentsCount;

- (NSArray<NSString *> *)getWaypointCategories:(BOOL)withDefaultCategory;
- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithColors:(BOOL)withDefaultCategory;
- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithCount:(BOOL)withDefaultCategory;
- (NSArray<NSDictionary<NSString *, NSString *> *> *)getWaypointCategoriesWithAllData:(BOOL)withDefaultCategory;

@end
