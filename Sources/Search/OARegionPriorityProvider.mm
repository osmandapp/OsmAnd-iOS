//
//  OARegionPriorityProvider.mm
//  OsmAnd
//
//  Created by Ivan Pyrohivskyi on 30.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OARegionPriorityProvider.h"
#import "OASearchPhrase.h"
#import "OASearchSettings.h"

static const int BBOX_STEP = 50000; // 50 km
static const int BBOX_MAX = 50000 * 20; // 1000 km
static const double LOCATION_SHIFT_THRESHOLD_METERS = 30000.0; // 30 km

@implementation OARegionPriorityProvider
{
    NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *_priorityMap;
    NSDictionary<NSString *, NSNumber *> *_regionsPriority;
    CLLocation * _searchLocation;
    NSInteger _lastIndexesCount;
}

- (instancetype) initWithPhrase:(OASearchPhrase *)phrase
{
    self = [super init];
    if (self)
    {
        _priorityMap = [NSMutableDictionary dictionary];
        if (phrase && phrase.getSettings)
        {
            _searchLocation = [phrase.getSettings getOriginalLocation];
            [self initPriorityMap:phrase];
        }
    }
    return self;
}

- (void) initPriorityMap:(OASearchPhrase *)phrase
{
    if (_searchLocation == nil)
    {
        return;
    }

    NSArray<NSString *> *indexes = [phrase getOfflineIndexes];
    if (indexes)
    {
        for (NSString *resId in indexes)
        {
            NSString * res = [resId lowerCase];
            int priority = [self calculatePriorityValue:res phrase:phrase];
            NSNumber *pKey = @(priority);
            if (!_priorityMap[pKey])
            {
                _priorityMap[pKey] = [NSMutableArray array];
            }
            [_priorityMap[pKey] addObject:res];
        }
    }
}

- (int) calculatePriorityValue:(NSString *)resId phrase:(OASearchPhrase *)phrase
{
    for (int i = 0; i * BBOX_STEP <= BBOX_MAX; i++)
    {
        QuadRect *rect = [OASearchPhrase calculateBbox:@((i * BBOX_STEP + 50)) location:_searchLocation];
        BOOL contains = [phrase containsData:[resId lowerCase]
                                        rect:rect
                            desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI)
                                   zoomLevel:OsmAnd::InvalidZoomLevel];
        if (contains)
        {
            return i;
        }
    }
    return BBOX_MAX / BBOX_STEP + 1;
}

- (void) initRegionsPriority
{
    if (_regionsPriority)
    {
        return;
    }
    NSMutableDictionary *tmpPriority = [NSMutableDictionary dictionary];
    NSArray *sortedKeys = [[_priorityMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *priority in sortedKeys)
    {
        for (NSString *resId in _priorityMap[priority])
        {
            if (!tmpPriority[resId])
            {
                tmpPriority[resId] = priority;
            }
        }
    }
    _regionsPriority = [tmpPriority copy];
}

- (NSArray<NSString *> *) getOfflineIndexes
{
    [self initRegionsPriority];
    NSMutableArray *result = [NSMutableArray array];
    NSArray *sortedKeys = [[_priorityMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *priority in sortedKeys)
    {
        for (NSString *resId in _priorityMap[priority])
        {
            if (![result containsObject:resId])
            {
                [result addObject:resId];
            }
        }
    }
    return result;
}

- (NSArray<NSString *> *) getOfflineIndexesWithMinRadius:(int)minRadius maxRadius:(int)maxRadius
{
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    int minPriority = (int)floor((double)minRadius / BBOX_STEP);
    int maxPriority = (int)ceil((double)maxRadius / BBOX_STEP);
    NSArray *sortedKeys = [[_priorityMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *pKey in sortedKeys)
    {
        int p = [pKey intValue];
        if (p >= minPriority && p <= maxPriority)
        {
            for (NSString *resId in _priorityMap[pKey])
            {
                if (![result containsObject:resId])
                {
                    [result addObject:resId];
                }
            }
        }
    }
    return result;
}

- (int) getRegionWeight:(NSString *)resourceId
{
    if (!resourceId || _priorityMap.count == 0)
    {
        return 0;
    }
    [self initRegionsPriority];
    NSNumber *priority = _regionsPriority[[resourceId lowerCase]];
    return priority ? [priority intValue] : 0;
}

- (void)checkAndUpdate:(OASearchPhrase *)phrase
{
    if (!phrase || ![phrase getSettings])
    {
        return;
    }

    CLLocation *newLocation = [[phrase getSettings] getOriginalLocation];
    NSArray<NSString *> *offlineIndexes = [phrase getOfflineIndexes];
    NSInteger cnt = offlineIndexes ? offlineIndexes.count : 0;

    if ([self shouldReinitializeWithLocation:newLocation count:cnt])
    {
        _searchLocation = newLocation ? newLocation : _searchLocation;
        _lastIndexesCount = cnt;
        [_priorityMap removeAllObjects];
        _regionsPriority = nil;
        [self initPriorityMap:phrase];
    }
}

- (BOOL)shouldReinitializeWithLocation:(CLLocation *)newLocation count:(NSInteger)cnt
{
    if (_searchLocation == nil || _lastIndexesCount != cnt)
    {
        return YES;
    }

    if (newLocation != nil)
    {
        CLLocationDistance distance = [_searchLocation distanceFromLocation:newLocation];
        return distance >= LOCATION_SHIFT_THRESHOLD_METERS;
    }
    return NO;
}

@end
