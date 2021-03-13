//
//  OARouteDirectionInfo.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteDirectionInfo.java
//  git revision fcd69744821733a04ce15dee7f111576bac478d6

#import <Foundation/Foundation.h>
#import "OAExitInfo.h"
#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <turnType.h>
#include <binaryRead.h>

@class OAExitInfo;

@interface OARouteDirectionInfo : NSObject
// location when you should action (turn or go ahead)
@property (nonatomic) int routePointOffset;
// location where direction end. useful for roundabouts.
@property (nonatomic) int routeEndPointOffset;
// Type of action to take
@property (nonatomic, assign) std::shared_ptr<TurnType> turnType;
// Speed after the action till next turn
@property (nonatomic) float averageSpeed;

// calculated vars
// after action (excluding expectedTime)
@property (nonatomic) long afterLeftTime;
// distance after action (for i.e. after turn to next turn)
@property (nonatomic) int distance;

@property (nonatomic) NSString* ref;
@property (nonatomic) NSString* streetName;
@property (nonatomic) NSString* destinationName;
@property (nonatomic) std::shared_ptr<RouteDataObject> routeDataObject;
@property (nonatomic) OAExitInfo *exitInfo;

- (instancetype)initWithAverageSpeed:(float)averageSpeed turnType:(std::shared_ptr<TurnType>)turnType;

- (NSString *) getDescriptionRoute;
- (NSString *) getDescriptionRoutePart;
- (NSString *) getDescriptionRoute:(int)collectedDistance;
- (void) setDescriptionRoute:(NSString *)descriptionRoute;

- (long) getExpectedTime;

@end
