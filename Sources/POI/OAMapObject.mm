//
//  OAMapObject.mm
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"
#import "OAMapObject+cpp.h"

@implementation OAMapObject
{
    NSMutableDictionary<NSString *, NSString *> *_localizedNames;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _x = [NSMutableArray new];
        _y = [NSMutableArray new];
        _localizedNames = [NSMutableDictionary new];
    }
    return self;
}

- (void) addLocation:(int)x y:(int)y
{
    [_x addObject:@(x)];
    [_y addObject:@(y)];
}

- (void) setName:(NSString * _Nullable)lang name:(NSString * _Nonnull)name
{
    if (!lang || lang.length == 0)
    {
        self.name = name;
    }
    else if ([lang isEqualToString:@"en"])
    {
        [self setEnName:name];
    }
    else
    {
        _localizedNames[lang] = name;
    }
}

- (NSString *) enName
{
    return _localizedNames[@"en"];
}

- (void)setEnName:(NSString *)enName
{
    _localizedNames[@"en"] = enName;
}

- (QVector< OsmAnd::LatLon >) getPolygon
{
    QVector<OsmAnd::LatLon> res;
    if (!_x)
        return res;
    for (int i = 0; i < _x.count; i++)
    {
        res.push_back(OsmAnd::LatLon(OsmAnd::Utilities::get31LatitudeY(_y[i].intValue), OsmAnd::Utilities::get31LongitudeX(_x[i].intValue)));
    }
    return res;
}

- (QVector< OsmAnd::PointI >) getPointsPolygon
{
    QVector<OsmAnd::PointI> res;
    if (!_x)
        return res;
    for (int i = 0; i < _x.count; i++)
    {
        res.push_back(OsmAnd::PointI(_y[i].intValue, _x[i].intValue));
    }
    return res;
}

@end
