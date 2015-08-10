//
//  OAGPXRouteDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"

@class OAGpxWpt;
@class OAGpxRoutePoint;
@class OAGpxRouteWptItem;

@interface OAGPXRouteDocument : OAGPXDocument

@property (strong, nonatomic) NSArray* locationPoints;
@property (strong, nonatomic) NSMutableArray* activePoints;
@property (strong, nonatomic) NSMutableArray* inactivePoints;
@property (strong, nonatomic) NSArray* groups;

@property (strong, nonatomic) NSObject *syncObj;

@property (readonly, nonatomic) double totalDistance;

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void)buildRouteTrack;
- (void)clearRouteTrack;

- (void)updateDistances;
- (void)updateDirections:(CLLocationDirection)newDirection myLocation:(CLLocationCoordinate2D)myLocation;

- (NSArray *)getWaypointsByGroup:(NSString *)groupName activeOnly:(BOOL)activeOnly;

- (void)includeGroupToRouting:(NSString *)groupName;
- (void)excludeGroupFromRouting:(NSString *)groupName;

- (BOOL) clearAndSaveTo:(NSString *)filename;

- (OAGpxRoutePoint *)addRoutePoint:(OAGpxWpt *)wpt;
- (void)removeRoutePoint:(OAGpxWpt *)wpt;

- (void)moveToInactiveByIndex:(NSInteger)index;
- (void)moveToInactive:(OAGpxRouteWptItem *)item;
- (void)moveToActive:(OAGpxRouteWptItem *)item;

- (void)updatePointsArray;
- (void)updatePointsArray:(BOOL)rebuildPointsOrder;

@end
