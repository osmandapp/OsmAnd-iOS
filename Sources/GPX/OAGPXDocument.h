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
#import <CoreLocation/CoreLocation.h>

#include <QList>
#include <QHash>
#include <QStack>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/GpxDocument.h>

@class OAGPXTrackAnalysis;
@class OASplitMetric, QuadRect, OAApplicationMode;

@interface OAGPXDocument : OAGpxExtensions

@property (nonatomic) OAMetadata* metadata;
@property (nonatomic) NSArray<OAGpxWpt *> *locationMarks;
@property (nonatomic) NSArray<OAGpxTrk *> *tracks;
@property (nonatomic) NSArray<OAGpxRte *> *routes;

@property (nonatomic) NSArray<OAGpxRouteSegment *> *routeSegments;
@property (nonatomic) NSArray<OAGpxRouteType *> *routeTypes;

@property (nonatomic) OAGpxBounds bounds;

@property (nonatomic) BOOL hasAltitude;

@property (nonatomic) NSString *version;
@property (nonatomic) NSString *creator;

@property (nonatomic, copy) NSString *path;

@property (nonatomic) OAGpxTrk *generalTrack;
@property (nonatomic) OAGpxTrkSeg *generalSegment;

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;
- (id)initWithGpxFile:(NSString *)filename;

- (BOOL) loadFrom:(NSString *)filename;
- (BOOL) fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;

- (BOOL) saveTo:(NSString *)filename;

- (BOOL) isCloudmadeRouteFile;

- (void) processPoints;
- (NSArray<OAGpxTrkSeg *> *) getPointsToDisplay;

- (BOOL) isEmpty;
- (void) addGeneralTrack;
- (OALocationMark *) findPointToShow;
- (BOOL) hasRtePt;
- (BOOL) hasWptPt;
- (BOOL) hasTrkPt;
- (BOOL) hasRoute;
- (BOOL) isRoutesPoints;

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp;

- (NSArray*) splitByDistance:(int)meters joinSegments:(BOOL)joinSegments;
- (NSArray*) splitByTime:(int)seconds joinSegments:(BOOL)joinSegments;
- (NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(int)metricLimit joinSegments:(BOOL)joinSegments;

- (NSArray<OAGpxRtePt *> *) getRoutePoints;
- (NSArray<OAGpxRtePt *> *) getRoutePoints:(NSInteger)routeIndex;
- (OAApplicationMode *) getRouteProfile;


+ (OAGpxWpt *)fetchWpt:(const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt>)mark;
+ (void)fillWpt:(std::shared_ptr<OsmAnd::GpxDocument::GpxWpt>)wpt usingWpt:(OAGpxWpt *)w;
+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata>)meta usingMetadata:(OAGpxMetadata *)m;
+ (void)fillTrack:(std::shared_ptr<OsmAnd::GpxDocument::GpxTrk>)trk usingTrack:(OAGpxTrk *)t;
+ (void)fillRoute:(std::shared_ptr<OsmAnd::GpxDocument::GpxRte>)rte usingRoute:(OAGpxRte *)r;

+ (void) fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray *)linkArray;
+ (void) fillExtension:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtension>&)extension ext:(OAGpxExtension *)e;
+ (void) fillExtensions:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions>&)extensions ext:(OAGpxExtensions *)ext;

- (void)initBounds;
- (void)processBounds:(CLLocationCoordinate2D)coord;
- (void)applyBounds;

- (double) getSpeed:(NSArray<OAGpxExtension *> *)extensions;

+ (NSString *)buildTrackSegmentName:(OAGPXDocument *)gpxFile
                              track:(OAGpxTrk *)track
                            segment:(OAGpxTrkSeg *)segment;
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

- (OAGpxTrk *) getGeneralTrack;
- (OAGpxTrkSeg *) getGeneralSegment;
- (NSArray<OAGpxTrkSeg *> *) getNonEmptyTrkSegments:(BOOL)routesOnly;
- (NSInteger) getNonEmptySegmentsCount;

- (NSArray<NSString *> *)getWaypointCategories:(BOOL)withDefaultCategory;
- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithColors:(BOOL)withDefaultCategory;
- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithCount:(BOOL)withDefaultCategory;
- (NSArray<NSDictionary<NSString *, NSString *> *> *)getWaypointCategoriesWithAllData:(BOOL)withDefaultCategory;

@end













