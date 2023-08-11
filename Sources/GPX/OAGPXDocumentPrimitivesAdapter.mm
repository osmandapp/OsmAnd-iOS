//
//  OAGPXDocumentPrimitivesAdapter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitivesAdapter.h"
#import "OAGPXDocumentPrimitives.h"

@implementation OAWptPtAdapter

- (instancetype)init
{
    self = [super init];
    if (self)
        _object = [[OAWptPt alloc] init];
    return self;
}

- (OAWptPt *)getObject
{
    if (_object && [_object isKindOfClass:OAWptPt.class])
        return (OAWptPt *)_object;
    return nil;
}

- (CLLocationCoordinate2D) position
{
    OAWptPt *obj = [self getObject];
    return obj ? obj.position : kCLLocationCoordinate2DInvalid;
}

- (void) setPosition:(CLLocationCoordinate2D)position
{
    OAWptPt *obj = [self getObject];
    if (obj)
        obj.position = position;
}

- (NSString *) name
{
    OAWptPt *obj = [self getObject];
    return obj ? obj.name : nil;
}

- (void) setName:(NSString *)name
{
    OAWptPt *obj = [self getObject];
    if (obj)
        obj.name = name;
}

@end
