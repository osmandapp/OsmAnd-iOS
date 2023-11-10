//
//  OAGPXDocumentAdapter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentAdapter.h"
#import "OAGPXDocument.h"

@implementation OAGPXDocumentAdapter

- (OAGPXDocument *)getObject
{
    return _object;
}

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    return [_object getAnalysis:fileTimestamp];
}

- (BOOL) hasAltitude
{
    return [_object hasAltitude];
}

- (int) pointsCount
{;
    return _object.points.count;
}

- (NSString *) getMetadataValueBy:(NSString *)tag
{
    OAGpxExtension *extension = [_object.metadata getExtensionByKey:tag];
    return extension ? extension.value : nil;
}

@end
