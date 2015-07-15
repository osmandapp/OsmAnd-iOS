//
//  OADestinationsHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationsHelper.h"
#import "OsmAndApp.h"
#import "OADestination.h"
#import "OAGpxRouteWptItem.h"
#import "OAUtilities.h"


@implementation OADestinationsHelper
{
    NSObject *_syncObj;
    OsmAndAppInstance _app;
}

@synthesize sortedDestinations = _sortedDestinations;

+ (OADestinationsHelper *)instance
{
    static dispatch_once_t once;
    static OADestinationsHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _syncObj = [[NSObject alloc] init];
        
        _sortedDestinations = [NSMutableArray array];
        
        [self initSortedDestinations];
    }
    return self;
}

-(NSMutableArray *)sortedDestinations
{
    @synchronized(_syncObj)
    {
        return _sortedDestinations;
    }
}

- (void)updateRoutePointsWithinDestinations:(NSArray *)routePoints
{
    @synchronized(_syncObj)
    {
        NSMutableArray *routeDestinations = [NSMutableArray array];
        
        if (routePoints)
        {
            [routePoints enumerateObjectsUsingBlock:^(OAGpxRouteWptItem *item, NSUInteger idx, BOOL *stop)
            {                
                OADestination *destination = [[OADestination alloc] initWithDesc:item.point.name latitude:item.point.position.latitude longitude:item.point.position.longitude];
                
                destination.routePoint = YES;
                
                NSUInteger objIndex = [_app.data.destinations indexOfObject:destination];
                if (objIndex != NSNotFound)
                    destination = _app.data.destinations[objIndex];
                
                destination.routePointIndex = idx;
                destination.routeTargetPoint = (item == [routePoints firstObject]);

                if (item.point.color)
                    destination.color = [OAUtilities colorFromString:item.point.color];
                else
                    destination.color = [UIColor whiteColor];
                
                [routeDestinations addObject:destination];
            }];
        }
        
        NSMutableArray *destinationsToRemove = [NSMutableArray array];
        for (OADestination *destination in _app.data.destinations)
            if (destination.routePoint && ![routeDestinations containsObject:destination])
                [destinationsToRemove addObject:destination];

        for (OADestination *destination in destinationsToRemove)
        {
            [_app.data.destinations removeObject:destination];
            [self.sortedDestinations removeObject:destination];
        }
        
        for (OADestination *destination in routeDestinations)
        {
            if (![_app.data.destinations containsObject:destination])
            {
                [_app.data.destinations addObject:destination];
                [self.sortedDestinations addObject:destination];
            }
        }

        [self.sortedDestinations enumerateObjectsUsingBlock:^(OADestination *destination, NSUInteger idx, BOOL *stop)
        {
            if (destination.routePoint && destination.routeTargetPoint && idx > 0)
            {
                OADestination *firstDestination = [self.sortedDestinations firstObject];
                if (firstDestination.routePoint)
                {
                    [self.sortedDestinations removeObject:firstDestination];
                    [self.sortedDestinations addObject:firstDestination];
                }
                [self.sortedDestinations removeObject:destination];
                [self.sortedDestinations insertObject:destination atIndex:0];

                *stop = YES;
            }
        }];
     
        [self refreshDestinationIndexes];
    }
}

- (void)refreshDestinationIndexes
{
    @synchronized(_syncObj)
    {
        [self.sortedDestinations enumerateObjectsUsingBlock:^(OADestination *destination, NSUInteger idx, BOOL *stop)
        {
            NSUInteger index = [_app.data.destinations indexOfObject:destination];
            ((OADestination *)_app.data.destinations[index]).index = idx;
        }];
    }
}

- (void)initSortedDestinations
{
    @synchronized(_syncObj)
    {
        NSArray *array = [_app.data.destinations sortedArrayUsingComparator:^NSComparisonResult(OADestination *destination1, OADestination *destination2)
        {
            if (destination2.index > destination1.index)
                return NSOrderedAscending;
            else if (destination2.index < destination1.index)
                return NSOrderedDescending;
            else
                return NSOrderedSame;
        }];
        
        [self.sortedDestinations addObjectsFromArray:array];
        
        [self refreshDestinationIndexes];
    }
}

- (NSInteger)pureDestinationsCount
{
    NSInteger res = 0;
    for (OADestination *destination in self.sortedDestinations)
        if (!destination.routePoint)
            res++;

    return res;
}

- (void)moveRoutePointOnTop:(NSInteger)pointIndex
{
    for (OADestination *destination in self.sortedDestinations)
    {
        if (destination.routePoint && destination.routePointIndex == pointIndex)
        {
            [self moveDestinationOnTop:destination];
            break;
        }
    }
}

- (void)moveDestinationOnTop:(OADestination *)destination
{
    @synchronized(_syncObj)
    {
        NSUInteger newIndex = 0;
        OADestination *firstDestination = [self.sortedDestinations firstObject];
        if (firstDestination.routePoint && firstDestination.routeTargetPoint)
            newIndex = 1;
        
        [self.sortedDestinations removeObject:destination];
        [self.sortedDestinations insertObject:destination atIndex:newIndex];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void)addDestination:(OADestination *)destination
{
    @synchronized(_syncObj)
    {
        [_app.data.destinations addObject:destination];
        [self.sortedDestinations addObject:destination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void)removeDestination:(OADestination *)destination
{
    @synchronized(_syncObj)
    {
        [_app.data.destinations removeObject:destination];
        [self.sortedDestinations removeObject:destination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

@end
