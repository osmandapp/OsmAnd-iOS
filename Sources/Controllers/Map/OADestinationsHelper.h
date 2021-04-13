//
//  OADestinationsHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMinDistanceFor2ndRowAutoSelection 100.0

@class OADestination;
@class OADestinationItem;
@class OAGPXDocument;

@interface OADestinationsHelper : NSObject

@property (nonatomic, readonly) NSMutableArray *sortedDestinations;
@property (nonatomic, readonly) OADestination *dynamic2ndRowDestination;

+ (OADestinationsHelper *) instance;

- (void) updateRoutePointsWithinDestinations:(NSArray *)routePoints rebuildPointsOrder:(BOOL)rebuildPointsOrder;
- (void) reorderDestinations:(NSArray<OADestinationItem *> *)reorderedDestinations;
- (void) replaceDestination:(OADestination *)destination withDestination:(OADestination *)newDestination;

- (void) addDestination:(OADestination *)destination;
- (void) removeDestination:(OADestination *)destination;
- (void) moveDestinationOnTop:(OADestination *)destination wasSelected:(BOOL)wasSelected;
- (void) moveRoutePointOnTop:(NSInteger)pointIndex;
- (void) apply2ndRowAutoSelection;

- (NSArray *) sortedDestinationsWithoutParking;

- (NSInteger) pureDestinationsCount;
- (OADestination *) getParkingPoint;

- (void) showOnMap:(OADestination *)destination;
- (void) hideOnMap:(OADestination *)destination;

- (void) addHistoryItem:(OADestination *)destination;

- (OAGPXDocument *) generateGpx:(NSArray<OADestination *> *)markers completeBackup:(BOOL)completeBackup;

+ (void) addParkingReminderToCalendar:(OADestination *)destination;
+ (void) removeParkingReminderFromCalendar:(OADestination *)destination;

@end
