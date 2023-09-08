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
    if (_object && [_object isKindOfClass:OAGPXDocument.class])
        return (OAGPXDocument *)_object;
    return nil;
}

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    OAGPXDocument *obj = [self getObject];
    return obj ? [obj getAnalysis:fileTimestamp] : nil;
}

- (BOOL) hasAltitude
{
    OAGPXDocument *obj = [self getObject];
    return obj ? [obj hasAltitude] : NO;
}

- (int) pointsCount
{
    OAGPXDocument *obj = [self getObject];
    return obj ? obj.points.count : 0;
}

@end
