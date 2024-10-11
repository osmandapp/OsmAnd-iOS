//
//  OAGpxData.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGpxData.h"
#import "OAGPXDocumentPrimitives.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore/GpxDocument.h>

@implementation OAGpxData

- (instancetype) initWithFile:(OASGpxFile *)gpxFile
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        if (_gpxFile) {
            auto rect = gpxFile.getRect;
            OAGpxBounds bounds;
            bounds.topLeft = CLLocationCoordinate2DMake(rect.top, rect.left);
            bounds.bottomRight = CLLocationCoordinate2DMake(rect.bottom, rect.right);
            bounds.center = CLLocationCoordinate2DMake(rect.centerY, rect.centerX);
            _rect = bounds;
        }
        else
        {
            OAGpxBounds bounds;
            bounds.topLeft.latitude = 0;
            bounds.topLeft.longitude = 0;
            bounds.bottomRight.latitude = 0;
            bounds.bottomRight.longitude = 0;
            _rect = bounds;
        }
    }
    return self;
}

@end
