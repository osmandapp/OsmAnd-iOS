//
//  OAGPXDocumentAdapter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentAdapter.h"
#import "OsmAndSharedWrapper.h"

@implementation OAGPXDocumentAdapter

- (OASGpxFile *)getObject
{
    return _object;
}

- (OASGpxTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    return [_object getAnalysisFileTimestamp:fileTimestamp];
}

- (BOOL)hasAltitude
{
    return [_object hasAltitude];
}

- (int)pointsCount
{
    return (int)_object.getAllPoints.count;
}

- (NSString *) getMetadataValueBy:(NSString *)tag
{
    return [_object.metadata getExtensionsToRead][tag];
}

@end
