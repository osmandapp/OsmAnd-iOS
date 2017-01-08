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

- (OAPOIType *) getPoiTypeByKeyName:(NSString *)name
{
    for (OAPOIType *p in _poiTypes)
    {
        if ([p.name isEqualToString:name])
            return p;
    }
    return nil;
}

- (NSMapTable<OAPOICategory *,  NSMutableSet<NSString *> *> *) putTypes:(NSMapTable<OAPOICategory *,  NSMutableSet<NSString *> *> *)acceptedTypes
{
    [acceptedTypes setObject:[OAPOIBaseType nullSet] forKey:self];
    [self.class addReferenceTypes:self.poiTypes acceptedTypes:acceptedTypes];
    return acceptedTypes;
}

+ (void) addReferenceTypes:(NSArray<OAPOIType *> *)pTypes acceptedTypes:(NSMapTable<OAPOICategory *,  NSMutableSet<NSString *> *> *)acceptedTypes
{
    for (OAPOIType *pt in pTypes)
    {
        if (pt.reference)
        {
            OAPOICategory *refCat = pt.referenceType.category;
            if (![acceptedTypes objectForKey:refCat])
                [acceptedTypes setObject:[NSMutableSet set] forKey:refCat];

            NSMutableSet<NSString *> *ls = [acceptedTypes objectForKey:refCat];
            if (ls)
                [ls addObject:pt.name];
        }
    }
}


@end
