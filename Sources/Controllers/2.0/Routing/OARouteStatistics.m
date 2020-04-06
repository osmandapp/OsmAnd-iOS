//
//  OARouteStatistics.m
//  OsmAnd
//
//  Created by Paul on 18.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteStatistics.h"

@implementation OARouteStatistics

- (instancetype) initWithName:(NSString *)name elements:(NSArray<OARouteSegmentAttribute *> *)elements partition:(NSDictionary<NSString *, OARouteSegmentAttribute *> *) partition totalDistance:(float)totalDistance {
    self = [super init];
    if (self) {
        _totalDistance = totalDistance;
        _name = name;
        _elements = elements;
        _partition = partition;
    }
    return self;
}

- (NSString *) toNSString
{
    NSMutableString *res = [NSMutableString stringWithFormat:@"Statistics '%@':", _name];
    for (OARouteSegmentAttribute *attr in _elements)
        [res appendFormat:@" %.0fm %@,", attr.distance, attr.userPropertyName];

    [res appendString:@"\n"];
    [res appendFormat:@" Partition: %@", _partition];
    return res;
}

@end

@implementation OARouteSegmentAttribute

- (instancetype) initWithPropertyName:(NSString *) propertyName color:(NSInteger) color slopeIndex:(NSInteger) slopeIndex boundariesClass:(NSArray<NSString *> *)boundariesClass
{
    self = [super init];
    if (self) {
        _propertyName = propertyName == nil ? kUndefinedAttr : propertyName;
        _slopeIndex = slopeIndex >= 0 && [boundariesClass[slopeIndex] hasSuffix:_propertyName] ? slopeIndex : -1;
        _color = color;
    }
    return self;
}

- (instancetype) initWithSegmentAttribute:(OARouteSegmentAttribute *) segmentAttribute
{
    self = [super init];
    if (self) {
        _propertyName = segmentAttribute.propertyName;
        _slopeIndex = segmentAttribute.slopeIndex;
        _color = segmentAttribute.color;
        _userPropertyName = segmentAttribute.userPropertyName;
    }
    return self;
}
    
- (NSString *) getUserPropertyName
{
    return _userPropertyName == nil ? _propertyName : _userPropertyName;
}

-(void) incrementDistanceBy:(float) distance
{
    _distance += distance;
}

- (NSString *) toNSString
{
    return [NSString stringWithFormat:@"%@ - %.0f m %ld", [self getUserPropertyName], _distance, _color];
}

@end
