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
@class OASplitMetric;

@interface OAGPXDocument : NSObject

@property (nonatomic) OAMetadata* metadata;
@property (nonatomic) NSArray *locationMarks;
@property (nonatomic) NSArray *tracks;
@property (nonatomic) NSArray *routes;
@property (nonatomic) OAExtraData *extraData;

@property (nonatomic) OAGpxBounds bounds;

@property (nonatomic) NSString *version;
@property (nonatomic) NSString *creator;

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;
- (id)initWithGpxFile:(NSString *)filename;

- (BOOL) saveTo:(NSString *)filename;

- (BOOL) isEmpty;
- (OAGpxWpt *) findPointToShow;

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp;

- (NSArray*) splitByDistance:(int)meters;
- (NSArray*) splitByTime:(int)seconds;
- (NSArray*) split:(OASplitMetric*)metric metricLimit:(int)metricLimit;

- (void) fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray *)linkArray;
- (void) fillExtension:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtension>&)extension ext:(OAGpxExtension *)e;
- (void) fillExtensions:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions>&)extensions ext:(OAGpxExtensions *)ext;

- (void)initBounds;
- (void)processBounds:(CLLocationCoordinate2D)coord;
- (void)applyBounds;

@end













