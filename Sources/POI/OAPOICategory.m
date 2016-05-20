//
//  OAPOICategory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOICategory.h"
#import "OAUtilities.h"
#import "OAPOIType.h"
#import "OAPOIFilter.h"

@implementation OAPOICategory

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOICategory class]])
    {
        OAPOICategory *obj = object;
        return [self.name isEqualToString:obj.name];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [self.name hash] + (self.tag ? [self.tag hash] : 1);
}

- (void)addPoiType:(OAPOIType *)poiType
{
    if (!_poiTypes)
    {
        _poiTypes = @[poiType];
    }
    else
    {
        _poiTypes = [_poiTypes arrayByAddingObject:poiType];
    }
}

- (void)addPoiFilter:(OAPOIFilter *)poiFilter
{
    if (!_poiFilters)
    {
        _poiFilters = @[poiFilter];
    }
    else
    {
        _poiFilters = [_poiFilters arrayByAddingObject:poiFilter];
    }
}

@end
