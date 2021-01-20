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
#import "QuadRect.h"

#include <OsmAndCore/GpxDocument.h>

@implementation OAGpxData

- (instancetype) initWithFile:(OAGPXMutableDocument *)gpxFile
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        if (_gpxFile)
            _rect = _gpxFile.getRect;
        else
            _rect = [[QuadRect alloc] initWithLeft:0. top:0. right:0. bottom:.0];
    }
    return self;
}

@end
