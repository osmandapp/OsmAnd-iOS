//
//  OARenderedObject.m
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OARenderedObject.h"

@implementation OARenderedObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _x = [NSMutableArray new];
        _y = [NSMutableArray new];
    }
    return self;
}

- (BOOL) isText
{
    return self.name && self.name.length > 0;
}

- (void) addLocation:(int)x y:(int)y
{
    [_x addObject:@(x)];
    [_y addObject:@(y)];
}

- (QVector<OsmAnd::PointI>) points
{
    QVector<OsmAnd::PointI> points;
    for (int i = 0; i < _x.count; i++)
    {
        points.push_back( OsmAnd::PointI(_x[i].intValue, _y[i].intValue) );
    }
    return points;
}

@end
