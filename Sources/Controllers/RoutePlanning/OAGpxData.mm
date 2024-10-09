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
            // FIXME:
            // _rect = _gpxFile.bounds;
            
            // NOTE: variant new code
//            OASGpxTrackAnalysis *analysis = [self.gpxFile getAnalysisFileTimestamp:0];
//            double clat = analysis.bottom / 2.0 + analysis.top / 2.0;
//            double clon = analysis.left / 2.0 + analysis.right / 2.0;
//            
//            OAGpxBounds bounds;
//            bounds.center = CLLocationCoordinate2DMake(clat, clon);
//            _rect = bounds;
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
