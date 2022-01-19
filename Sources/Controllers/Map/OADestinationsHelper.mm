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
#import "OALog.h"
#import "Localization.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OADestinationItem.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDocumentPrimitives.h"


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

- (instancetype) init
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

- (NSMutableArray *) sortedDestinations
{
    @synchronized(_syncObj)
    {
        return _sortedDestinations;
    }
}

- (NSArray *) sortedDestinationsWithoutParking
{
    @synchronized(_syncObj)
    {
        return [NSArray arrayWithArray:_sortedDestinations];
    }
}

- (void) reorderDestinations:(NSArray<OADestinationItem *> *)reorderedDestinations
{
    @synchronized(_syncObj)
    {
        NSMutableArray<OADestination *> *newDestinations = [NSMutableArray new];
        for (OADestinationItem *item in reorderedDestinations)
        {
            [newDestinations addObject:item.destination];
        }
        _sortedDestinations = newDestinations;
        [self refreshDestinationIndexes];
        [_app.data.destinationsChangeObservable notifyEvent];
    }
}

- (void) refreshDestinationIndexes
{
    @synchronized(_syncObj)
    {
        [_sortedDestinations enumerateObjectsUsingBlock:^(OADestination *destination, NSUInteger idx, BOOL *stop)
        {
            NSUInteger index = [_app.data.destinations indexOfObject:destination];
            if (index != NSNotFound)
                ((OADestination *)_app.data.destinations[index]).index = idx;
        }];
    }
}

- (void) initSortedDestinations
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
        
        
        for (OADestination *destination in array)
            if (!destination.hidden)
                [_sortedDestinations addObject:destination];
        
        [self refreshDestinationIndexes];
    }
}

- (NSInteger) pureDestinationsCount
{
    NSInteger res = 0;
    for (OADestination *destination in _app.data.destinations)
        if (!destination.hidden)
            res++;

    return res;
}

- (void) moveDestinationOnTop:(OADestination *)destination wasSelected:(BOOL)wasSelected
{
    @synchronized(_syncObj)
    {
        NSUInteger newIndex = 0;
        OADestination *firstDestination = [_sortedDestinations firstObject];
        
        [_sortedDestinations removeObject:destination];
        [_sortedDestinations insertObject:destination atIndex:newIndex];
        
        if (wasSelected)
        {
            for (OADestination *d in self.sortedDestinations)
                d.manual = NO;
            
            destination.manual = wasSelected;
        }
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) apply2ndRowAutoSelection
{
    BOOL wasSelected = NO;
    
    @synchronized(_syncObj)
    {
        if (self.sortedDestinations.count < 2)
            return;
        
        CLLocation* currLoc = _app.locationServices.lastKnownLocation;
        if (!currLoc)
            return;
        
        double lat = currLoc.coordinate.latitude;
        double lon = currLoc.coordinate.longitude;

        BOOL isManualSelected = NO;
        for (OADestination *destination in self.sortedDestinations)
            if (destination.manual)
            {
                isManualSelected = YES;
                break;
            }
        
        CGFloat distance = kMinDistanceFor2ndRowAutoSelection;
        OADestination *closestDestination;
        
        for (OADestination *destination in self.sortedDestinations)
        {
            double destDist = [destination distance:lat longitude:lon];
            if (destDist < distance)
            {
                closestDestination = destination;
                distance = destDist;
            }
        }
        
        if (closestDestination && closestDestination.index > 1)
        {
            if (closestDestination != _dynamic2ndRowDestination)
            {
                _dynamic2ndRowDestination = closestDestination;
                wasSelected = YES;
            }
        }
        else
        {
            wasSelected = _dynamic2ndRowDestination != nil;
            _dynamic2ndRowDestination = nil;
        }
    }

    if (wasSelected)
        [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) addDestination:(OADestination *)destination
{
    @synchronized(_syncObj)
    {
        [_app.data.destinations addObject:destination];
        [_sortedDestinations addObject:destination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationAddObservable notifyEventWithKey:destination];
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) replaceDestination:(OADestination *)destination withDestination:(OADestination *)newDestination
{
    @synchronized(_syncObj)
    {
        if (destination == _dynamic2ndRowDestination)
            _dynamic2ndRowDestination = newDestination;
        
        [_app.data.destinations removeObject:destination];
        [_app.data.destinations addObject:newDestination];
        
        [_sortedDestinations replaceObjectAtIndex:destination.index withObject:newDestination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationRemoveObservable notifyEventWithKey:destination];
    [_app.data.destinationAddObservable notifyEventWithKey:newDestination];
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) removeDestination:(OADestination *)destination
{
    @synchronized(_syncObj)
    {
        if (destination == _dynamic2ndRowDestination)
            _dynamic2ndRowDestination = nil;
        
        [_app.data.destinations removeObject:destination];
        [_sortedDestinations removeObject:destination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationRemoveObservable notifyEventWithKey:destination];
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) showOnMap:(OADestination *)destination
{
    destination.hidden = NO;
    [_app.data.destinationShowObservable notifyEventWithKey:destination];

    @synchronized(_syncObj)
    {
        [_sortedDestinations addObject:destination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) hideOnMap:(OADestination *)destination
{
    destination.hidden = YES;
    [_app.data.destinationHideObservable notifyEventWithKey:destination];
    
    @synchronized(_syncObj)
    {
        [_sortedDestinations removeObject:destination];
        
        [self refreshDestinationIndexes];
    }
    
    [_app.data.destinationsChangeObservable notifyEvent];
}

- (void) addHistoryItem:(OADestination *)destination
{
    OAHistoryItem *h = [[OAHistoryItem alloc] init];
    h.name = destination.desc;
    h.latitude = destination.latitude;
    h.longitude = destination.longitude;
    h.date = [NSDate date];
    
    h.hType = OAHistoryTypeDirection;
    
    [[OAHistoryHelper sharedInstance] addPoint:h];
}

- (OAGPXDocument *) generateGpx:(NSArray<OADestination *> *)markers completeBackup:(BOOL)completeBackup
{
    OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] init];
    [doc setVersion:[NSString stringWithFormat:@"%@ %@", @"OsmAnd",
                     [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]]];
    for (OADestination *marker in markers)
    {
        OAGpxWpt *wpt = [[OAGpxWpt alloc] init];
        wpt.position = CLLocationCoordinate2DMake(marker.latitude, marker.longitude);
        wpt.name = marker.desc;
        [wpt setColor:[OAUtilities colorToNumber:marker.color]];

        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"creation_date";

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
        e.value = [dateFormatter stringFromDate:marker.creationDate];;

        wpt.extensions = @[e];

//        if (completeBackup)
//        {
//            if (marker.creationDate != 0) {
//                wpt.getExtensionsToWrite().put(CREATION_DATE, format.format(new Date(marker.creationDate)));
//            }
//            if (marker.visitedDate != 0) {
//                wpt.getExtensionsToWrite().put(VISITED_DATE, format.format(new Date(marker.visitedDate)));
//            }
//        }
        [doc addWpt:wpt];
    }
    return doc;
}

@end
