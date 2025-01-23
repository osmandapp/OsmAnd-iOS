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

- (void) setName:(NSString *)lang name:(NSString *)name
{
    if (!lang || lang.length == 0)
    {
        self.name = name;
    }
    else if ([lang isEqualToString:@"en"])
    {
        self.enName = name;
    }
    else
    {
        if (!_localizedNames)
            _localizedNames = [NSMutableDictionary new];
        _localizedNames[lang] = name;
    }
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

@end
