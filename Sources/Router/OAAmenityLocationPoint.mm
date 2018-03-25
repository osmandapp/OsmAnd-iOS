//
//  OAAmenityLocationPoint.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAmenityLocationPoint.h"
#import "OAPOI.h"
#import "OAPointDescription.h"
#import "OAPOIHelper.h"

@implementation OAAmenityLocationPoint

- (instancetype) initWithPoi:(OAPOI *)poi
{
    self = [super init];
    if (self)
    {
        _poi = poi;
    }
    return self;
}

#pragma mark - OALocationPoint

- (double) getLatitude
{
    return _poi.latitude;
}

- (double) getLongitude
{
    return _poi.longitude;
}

- (UIColor *) getColor
{
    return nil;
}

- (BOOL) isVisible
{
    return YES;
}

- (OAPointDescription *) getPointDescription
{
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_POI name:[[OAPOIHelper sharedInstance] getPoiStringWithoutType:_poi]];
}

@end
