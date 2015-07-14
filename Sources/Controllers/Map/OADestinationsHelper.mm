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

@implementation OADestinationsHelper
{
    NSObject *_syncObj;
    OsmAndAppInstance _app;
}

@synthesize topDestinations = _topDestinations;

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
        [self refreshTopDestinations];
    }
    return self;
}

-(NSArray *)topDestinations
{
    @synchronized(_syncObj)
    {
        return _topDestinations;
    }
}

- (void)refreshTopDestinations
{
    @synchronized(_syncObj)
    {
        OADestination *first;
        OADestination *second;
        NSInteger firstIndex = -1;
        NSInteger secondIndex = -1;
        
        NSInteger index = 0;
        for (OADestination *destination in _app.data.destinations)
        {
            if (!first || (!first.routePoint && destination.routePoint) || (!first.routePoint && !destination.routePoint && destination.showOnTop))
            {
                if (!first.routePoint && !destination.routePoint && destination.showOnTop)
                {
                    second = first;
                    secondIndex = firstIndex;
                }
                first = destination;
                firstIndex = index;
            }
            else if (!second || (second.routePoint && !destination.routePoint) || (!destination.routePoint && destination.showOnTop))
            {
                second = destination;
                secondIndex = index;
            }
            
            index++;
        }

        if (firstIndex == -1)
        {
            _topDestinations = @[];
            return;
        }
        else if (secondIndex == -1)
        {
            _topDestinations = @[[NSNumber numberWithInteger:firstIndex]];
            return;
        }
        
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        if (newLocation)
        {
            double distanceToFirst = [first distance:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
            double distanceToSecond = [second distance:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
            
            if (distanceToSecond < distanceToFirst && distanceToFirst <= 20.0)
                _topDestinations = @[[NSNumber numberWithInteger:secondIndex], [NSNumber numberWithInteger:firstIndex]];
            else
                _topDestinations = @[[NSNumber numberWithInteger:firstIndex], [NSNumber numberWithInteger:secondIndex]];
        }
        else
        {
            _topDestinations = @[[NSNumber numberWithInteger:firstIndex], [NSNumber numberWithInteger:secondIndex]];
        }
    }
}

- (NSInteger)pureDestinationsCount
{
    NSInteger res = 0;
    for (OADestination *destination in _app.data.destinations)
        if (!destination.routePoint)
            res++;

    return res;
}

- (void)showDestinationOnTop:(OADestination *)destination
{
    for (OADestination *d in _app.data.destinations)
        if (!d.routePoint)
            d.showOnTop = NO;
    
    destination.showOnTop = YES;
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

@end
