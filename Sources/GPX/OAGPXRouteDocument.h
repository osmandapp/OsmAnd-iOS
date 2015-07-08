//
//  OAGPXRouteDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"



@interface OAGPXRouteDocument : OAGPXDocument

@property (strong, nonatomic) NSArray* locationPoints;
@property (strong, nonatomic) NSMutableArray* activePoints;
@property (strong, nonatomic) NSMutableArray* inactivePoints;
@property (strong, nonatomic) NSArray* groups;

@property (readonly, nonatomic) double totalDistance;

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void)buildRouteTrack;

- (void)updateDistances;
- (void)updateDirections:(CLLocationDirection)newDirection myLocation:(CLLocationCoordinate2D)myLocation;

@end
