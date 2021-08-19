//
//  OAGpxData.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGpxData.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDocumentPrimitives.h"

#include <OsmAndCore/GpxDocument.h>

@implementation OAGpxData

- (instancetype) initWithFile:(OAGPXMutableDocument *)gpxFile
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        if (_gpxFile)
            _rect = _gpxFile.bounds;
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
