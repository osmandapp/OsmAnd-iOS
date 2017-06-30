//
//  OARouteDirectionInfo.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore.h>
#include <turnType.h>

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
@property (nonatomic) int afterLeftTime;
// distance after action (for i.e. after turn to next turn)
@property (nonatomic) int distance;

@property (nonatomic) NSString* ref;
@property (nonatomic) NSString* streetName;
@property (nonatomic) NSString* destinationName;

- (instancetype)initWithAverageSpeed:(float)averageSpeed turnType:(std::shared_ptr<TurnType>)turnType;

- (NSString *) getDescriptionRoute;
- (NSString *) getDescriptionRoute:(int)collectedDistance;
- (void) setDescriptionRoute:(NSString *)descriptionRoute;

@end
