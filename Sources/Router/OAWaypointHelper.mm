//
//  OAWaypointHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAWaypointHelper.h"
#import "OARouteCalculationResult.h"
#import "OAApplicationMode.h"
#import "OALocationPointWrapper.h"
#import "OALocationPoint.h"
#import "OAAmenityLocationPoint.h"

#define NOT_ANNOUNCED 0
#define ANNOUNCED_ONCE 1
#define ANNOUNCED_DONE 2

#define LONG_ANNOUNCE_RADIUS 700
#define SHORT_ANNOUNCE_RADIUS 150
#define ALARMS_ANNOUNCE_RADIUS 150

// don't annoy users by lots of announcements
#define APPROACH_POI_LIMIT 1
#define ANNOUNCE_POI_LIMIT 3

@implementation OAWaypointHelper
{
    int searchDeviationRadius;
    int poiSearchDeviationRadius;

    NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *locationPoints;
    NSMapTable<id<OALocationPoint>, NSNumber *> *locationPointsStates;
    NSMutableArray<NSNumber *> *pointsProgress;
    OARouteCalculationResult *route;
    
    long announcedAlarmTime;
    OAApplicationMode *appMode;
}

+ (OAWaypointHelper *) sharedInstance
{
    static OAWaypointHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWaypointHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        searchDeviationRadius = 500;
        poiSearchDeviationRadius = 100;
        
        locationPoints = [NSMutableArray array];
        pointsProgress = [NSMutableArray array];
        locationPointsStates = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void) setNewRoute:(OARouteCalculationResult *)route
{
    // TODO
    //List<List<LocationPointWrapper>> locationPoints = new ArrayList<List<LocationPointWrapper>>();
    //recalculatePoints(route, -1, locationPoints);
    //setLocationPoints(locationPoints, route);
}

@end
