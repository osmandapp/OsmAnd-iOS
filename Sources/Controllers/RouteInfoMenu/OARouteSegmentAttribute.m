//
//  OARouteSegmentAttribute.m
//  OsmAnd
//
//  Created by Paul on 18.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteSegmentAttribute.h"

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

@end
