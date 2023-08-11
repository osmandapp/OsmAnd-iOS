//
//  OAPOIAdapter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAPOIAdapter.h"
#import "OAPOI.h"

@implementation OAPOIAdapter

- (instancetype)init
{
    self = [super init];
    if (self)
        _object = [[OAPOI alloc] init];
    return self;
}

- (OAPOI *)getObject
{
    if (_object && [_object isKindOfClass:OAPOI.class])
        return (OAPOI *)_object;
    return nil;
}

- (NSString *) name
{
    OAPOI *obj = [self getObject];
    return obj ? obj.name : nil;
}

- (void) setName:(NSString *)name
{
    OAPOI *obj = [self getObject];
    if (obj)
        obj.name = name;
}

- (double) latitude
{
    OAPOI *obj = [self getObject];
    return obj ? obj.latitude : NAN;
}

- (void) setLatitude:(double)latitude
{
    OAPOI *obj = [self getObject];
    if (obj)
        obj.latitude = latitude;
}

- (double) longitude
{
    OAPOI *obj = [self getObject];
    return obj ? obj.longitude : NAN;
}

- (void) setLongitude:(double)longitude
{
    OAPOI *obj = [self getObject];
    if (obj)
        obj.longitude = longitude;
}

@end
