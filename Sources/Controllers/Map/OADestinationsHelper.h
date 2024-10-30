//
//  OADestinationsHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMinDistanceFor2ndRowAutoSelection 100.0

@class OADestination, OADestinationItem, OASGpxFile;

@interface OADestinationsHelper : NSObject

@property (nonatomic, readonly) NSMutableArray<OADestination *> *sortedDestinations;
@property (nonatomic, readonly) OADestination *dynamic2ndRowDestination;

+ (OADestinationsHelper *) instance;

- (void) reorderDestinations:(NSArray<OADestinationItem *> *)reorderedDestinations;
- (void) replaceDestination:(OADestination *)destination withDestination:(OADestination *)newDestination;

- (void) addDestination:(OADestination *)destination;
- (void) removeDestination:(OADestination *)destination;
- (void) markAsVisited:(OADestination *)destination;
- (void) moveDestinationOnTop:(OADestination *)destination wasSelected:(BOOL)wasSelected;
- (void) apply2ndRowAutoSelection;
- (UIColor *) generateColorForDestination:(OADestination *)destination;
- (UIColor *) addDestinationWithNewColor:(OADestination *)destination;

- (NSArray<OADestination *> *) sortedDestinationsWithoutParking;

- (NSInteger) pureDestinationsCount;

- (void) showOnMap:(OADestination *)destination;
- (void) hideOnMap:(OADestination *)destination;

- (void) addHistoryItem:(OADestination *)destination;

- (OASGpxFile *) generateGpx:(NSArray<OADestination *> *)markers completeBackup:(BOOL)completeBackup;

- (long) getMarkersLastModifiedTime;
- (void) setMarkersLastModifiedTime:(long)lastModified;

@end
