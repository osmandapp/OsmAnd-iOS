//
//  OAGpxData.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGpxData.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "QuadRect.h"

#include <OsmAndCore/GpxDocument.h>

@implementation OAGpxData

- (instancetype) initWithFile:(OAGPXDocument *)gpxFile rect:(QuadRect *)rect actionType:(EOAActionType)actionType trkSegment:(OATrackSegment *)trkSegment
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        _rect = rect;
        _actionType = actionType;
        _trkSegment = trkSegment;
    }
    return self;
}

- (instancetype) initWithFile:(OAGPXDocument *)gpxFile gpxData:(OAGpxData *)gpxData
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        _rect = gpxData.rect;
        _actionType = gpxData.actionType;
        _trkSegment = gpxData.trkSegment;
    }
    return self;
}

@end
