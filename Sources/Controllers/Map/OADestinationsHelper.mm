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
#import "OAUtilities.h"
#import "OALocationServices.h"
#import "OAObservable.h"
#import "OALog.h"
#import "Localization.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OADestinationItem.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAAppVersion.h"
#import "OAColors.h"
#import "OAAppData.h"
#import "OAAppSettings.h"

#define kMarkersChanged @"markers_modified_time"

@implementation OADestinationsHelper
{
    NSObject *_syncObj;
    OsmAndAppInstance _app;
    
    OACommonLong *_markersModificationDate;

    NSArray *_colors;
    NSArray *_markerNames;
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
        _markersModificationDate = [[OACommonLong withKey:kMarkersChanged defValue:0] makeGlobal];

        _colors = @[UIColorFromRGB(marker_pin_color_orange),
                    UIColorFromRGB(marker_pin_color_teal),
                    UIColorFromRGB(marker_pin_color_green),
                    UIColorFromRGB(marker_pin_color_red),
                    UIColorFromRGB(marker_pin_color_light_green),
                    UIColorFromRGB(marker_pin_color_purple),
                    UIColorFromRGB(marker_pin_color_blue)];

        _markerNames = @[@"ic_destination_pin_1",
                         @"ic_destination_pin_2",
                         @"ic_destination_pin_3",
                         @"ic_destination_pin_4",
                         @"ic_destination_pin_5",
                         @"ic_destination_pin_6",
                         @"ic_destination_pin_7"];

        [self initSortedDestinations];
    }
    return self;
}

- (NSMutableArray<OADestination *> *) sortedDestinations
{
    @synchronized(_syncObj)
    {
        return _sortedDestinations;
    }
}

- (NSArray<OADestination *> *) sortedDestinationsWithoutParking
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
        for (OADestination *item in _sortedDestinations)
        {
            if (![newDestinations containsObject:item])
            {
                [self addHistoryItem:item];
                if (item == _dynamic2ndRowDestination)
                    _dynamic2ndRowDestination = nil;
                [_app.data.destinations removeObject:item];
                [_app.data.destinationRemoveObservable notifyEventWithKey:item];
            }
        }
        _sortedDestinations = newDestinations;
        [self refreshDestinationIndexes];
        [_app.data.destinationsChangeObservable notifyEvent];
        [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
    }
}

- (long) getMarkersLastModifiedTime
{
    return [_markersModificationDate get];
}

- (void) setMarkersLastModifiedTime:(long)lastModified
{
    [_markersModificationDate set:lastModified];
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
}

- (UIColor *) generateColorForDestination:(OADestination *)destination
{
    int colorIndex = [self getFreeColorIndex];
    UIColor *color = _colors[colorIndex];
    destination.color = color;
    destination.markerResourceName = _markerNames[colorIndex];
    return color;
}

- (UIColor *) addDestinationWithNewColor:(OADestination *)destination
{
    UIColor *color = [self generateColorForDestination:destination];
    [self addDestination:destination];
    return color;
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
}

- (void) markAsVisited:(OADestination *)destination
{
    [self addHistoryItem:destination];
    [self removeDestination:destination];
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
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
    [self setMarkersLastModifiedTime:NSDate.date.timeIntervalSince1970];
}

- (void) addHistoryItem:(OADestination *)destination
{
    if ([[OAAppSettings sharedManager].mapMarkersHistory get])
    {
        OAHistoryItem *h = [[OAHistoryItem alloc] init];
        h.name = destination.desc;
        h.latitude = destination.latitude;
        h.longitude = destination.longitude;
        h.date = [NSDate date];
        h.iconName = @"ic_custom_marker";
        h.hType = OAHistoryTypeDirection;
        
        [[OAHistoryHelper sharedInstance] addPoint:h];
    }
}

- (OAGPXDocument *) generateGpx:(NSArray<OADestination *> *)markers completeBackup:(BOOL)completeBackup
{
    OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] init];
    for (OADestination *marker in markers)
    {
        OAWptPt *wpt = [[OAWptPt alloc] init];
        wpt.position = CLLocationCoordinate2DMake(marker.latitude, marker.longitude);
        wpt.name = marker.desc;
        [wpt setColor:[marker.color toARGBNumber]];

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

- (int) getFreeColorIndex
{
    for (int i = 0; i < _colors.count; i++)
    {
        UIColor *c = _colors[i];
        BOOL colorExists = NO;
        for (OADestination *destination in _app.data.destinations)
            if ([UIColor colorRGB:destination.color equalToColorRGB:c])
            {
                colorExists = YES;
                break;
            }

        if (!colorExists)
            return i;
    }

    UIColor *lastUsedColor;
    for (long i = (long) _app.data.destinations.count - 1; i >= 0; i--)
    {
        OADestination *destination = _app.data.destinations[i];
        if (destination.color)
        {
            lastUsedColor = destination.color;
            break;
        }
    }

    if (lastUsedColor)
    {
        for (int i = 0; i < _colors.count; i++)
        {
            UIColor *c = _colors[i];
            if ([UIColor colorRGB:lastUsedColor equalToColorRGB:c])
            {
                int res = i + 1;
                if (res >= _colors.count)
                    res = 0;
                return res;
            }
        }
    }

    return 0;
}

@end
