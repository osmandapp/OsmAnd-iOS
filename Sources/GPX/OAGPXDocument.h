//
//  OAGPXDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndCore/GpxDocument.h"
#import "OAGPXDocumentPrimitives.h"

@class OAGPXTrackAnalysis;
@class OASplitMetric;

@interface OAGPXDocument : NSObject

@property (nonatomic) OAMetadata* metadata;
@property (nonatomic) NSArray *locationMarks;
@property (nonatomic) NSArray *tracks;
@property (nonatomic) NSArray *routes;
@property (nonatomic) OAExtraData *extraData;

@property (nonatomic) NSString *version;
@property (nonatomic) NSString *creator;

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;
- (id)initWithGpxFile:(NSString *)filename;

- (void) saveTo:(NSString *)filename;

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp;

- (NSArray*) splitByDistance:(int)meters;
- (NSArray*) splitByTime:(int)seconds;
- (NSArray*) split:(OASplitMetric*)metric metricLimit:(int)metricLimit;

@end















