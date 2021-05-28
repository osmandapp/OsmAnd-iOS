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

#import <EventKit/EventKit.h>


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
        NSMutableArray *allDestinations = [NSMutableArray arrayWithArray:_sortedDestinations];
        [allDestinations removeObject:self.getParkingPoint];
        return [NSArray arrayWithArray:allDestinations];
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

- (void) updateRoutePointsWithinDestinations:(NSArray *)routePoints rebuildPointsOrder:(BOOL)rebuildPointsOrder
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
                if (objIndex != NSNotFound && !rebuildPointsOrder)
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
        
        BOOL isSecondDestinationRoute = (_sortedDestinations.count > 1 && ((OADestination *)_sortedDestinations[1]).routePoint);

        NSMutableArray *destinationsToRemove = [NSMutableArray array];
        for (OADestination *destination in _app.data.destinations)
            if (destination.routePoint && (![routeDestinations containsObject:destination] || rebuildPointsOrder))
                [destinationsToRemove addObject:destination];
        
        for (OADestination *destination in destinationsToRemove)
        {
            [_app.data.destinations removeObject:destination];
            [_sortedDestinations removeObject:destination];
        }
        
        if (rebuildPointsOrder)
        {
            [routeDestinations enumerateObjectsUsingBlock:^(OADestination *destination, NSUInteger idx, BOOL *stop) {
                
                [_app.data.destinations addObject:destination];

                if (idx == 0)
                    [_sortedDestinations insertObject:destination atIndex:0];
                else if (idx == 1 && isSecondDestinationRoute)
                    [_sortedDestinations insertObject:destination atIndex:1];
                else
                    [_sortedDestinations addObject:destination];
            }];
        }
        else
        {
            for (OADestination *destination in routeDestinations)
            {
                if (![_app.data.destinations containsObject:destination])
                {
                    [_app.data.destinations addObject:destination];
                    [_sortedDestinations addObject:destination];
                }
            }
            
            [_sortedDestinations enumerateObjectsUsingBlock:^(OADestination *destination, NSUInteger idx, BOOL *stop)
             {
                 if (destination.routePoint && destination.routeTargetPoint && idx > 0)
                 {
                     OADestination *firstDestination = [_sortedDestinations firstObject];
                     if (firstDestination.routePoint)
                     {
                         [_sortedDestinations removeObject:firstDestination];
                         [_sortedDestinations addObject:firstDestination];
                     }
                     [_sortedDestinations removeObject:destination];
                     [_sortedDestinations insertObject:destination atIndex:0];
                     
                     *stop = YES;
                 }
             }];
        }
        
        [self refreshDestinationIndexes];
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
        if (!destination.routePoint && !destination.hidden)
            res++;

    return res;
}

- (OADestination *) getParkingPoint
{
    for (OADestination *destination in _app.data.destinations)
        if (destination.parking)
            return destination;
    
    return nil;
}

- (void) moveRoutePointOnTop:(NSInteger)pointIndex
{
    for (OADestination *destination in self.sortedDestinations)
    {
        if (destination.routePoint && destination.routePointIndex == pointIndex)
        {
            [self moveDestinationOnTop:destination wasSelected:YES];
            break;
        }
    }
}

- (void) moveDestinationOnTop:(OADestination *)destination wasSelected:(BOOL)wasSelected
{
    @synchronized(_syncObj)
    {
        NSUInteger newIndex = 0;
        OADestination *firstDestination = [_sortedDestinations firstObject];
        if (firstDestination.routePoint && firstDestination.routeTargetPoint)
            newIndex = 1;
        
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
        
        BOOL isRoute = ((OADestination *)self.sortedDestinations[0]).routePoint;
        
        CGFloat distance = kMinDistanceFor2ndRowAutoSelection;
        OADestination *closestDestination;
        
        for (OADestination *destination in self.sortedDestinations)
        {
            double destDist = [destination distance:lat longitude:lon];
            if (((isRoute && !isManualSelected && destination.routePoint && !destination.routeTargetPoint) ||
                 (!isRoute && !destination.routePoint)) && destDist < distance)
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
        if (destination.parking)
            [OADestinationsHelper removeParkingReminderFromCalendar:destination];

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
    
    if (!destination.routePoint)
        h.hType = (destination.parking ?  OAHistoryTypeParking : OAHistoryTypeDirection);
    else
        h.hType = OAHistoryTypeRouteWpt;
    
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
        wpt.color = marker.color.toHexString;

        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"creation_date";

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
        e.value = [dateFormatter stringFromDate:marker.creationDate];;

        ext.extensions = @[e];
        wpt.extraData = ext;

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

+ (void) addParkingReminderToCalendar:(OADestination *)destination
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_access_calendar") message:error.localizedDescription delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            }
            else if (!granted)
            {
                [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_access_calendar") message:OALocalizedString(@"reminder_not_set_text") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            }
            else
            {
                EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                event.title = OALocalizedString(@"pickup_car");
                
                event.startDate = destination.carPickupDate;
                event.endDate = destination.carPickupDate;
                
                [event addAlarm:[EKAlarm alarmWithRelativeOffset:-60.0 * 5.0]];
                
                [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                NSError *err;
                [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                if (err)
                    [[[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
                else
                    destination.eventIdentifier = [event.eventIdentifier copy];
            }
        });
    }];
}

+ (void) removeParkingReminderFromCalendar:(OADestination *)destination
{
    if (destination.eventIdentifier)
    {
        EKEventStore *eventStore = [[EKEventStore alloc] init];
        EKEvent *event = [eventStore eventWithIdentifier:destination.eventIdentifier];
        NSError *error;
        if (![eventStore removeEvent:event span:EKSpanFutureEvents error:&error])
            OALog(@"%@", [error localizedDescription]);
        else
            destination.eventIdentifier = nil;
    }
}

@end
