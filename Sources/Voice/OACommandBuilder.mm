//
//  OACommandBuilder.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
#import <JavaScriptCore/JavaScriptCore.h>
#import "OACommandBuilder.h"
#import "OACommandPlayer.h"

@implementation OACommandBuilder
{
    id<OACommandPlayer> commandPlayer;
    BOOL alreadyExecuted;
    NSMutableArray *listStruct;
    JSContext *context;
}

static NSString * const C_PREPARE_TURN = @"prepare_turn";
static NSString * const C_PREPARE_ROUNDABOUT = @"prepare_roundabout";
static NSString * const C_PREPARE_MAKE_UT = @"prepare_make_ut";
static NSString * const C_ROUNDABOUT = @"roundabout";
static NSString * const C_GO_AHEAD = @"go_ahead";
static NSString * const C_TURN = @"turn";
static NSString * const C_MAKE_UT = @"make_ut";
static NSString * const C_MAKE_UTWP = @"make_ut_wp";
static NSString * const C_AND_ARRIVE_DESTINATION = @"and_arrive_destination";
static NSString * const C_REACHED_DESTINATION = @"reached_destination";
static NSString * const C_AND_ARRIVE_INTERMEDIATE = @"and_arrive_intermediate";
static NSString * const C_REACHED_INTERMEDIATE = @"reached_intermediate";
static NSString * const C_AND_ARRIVE_WAYPOINT = @"and_arrive_waypoint";
static NSString * const C_AND_ARRIVE_FAVORITE = @"and_arrive_favorite";
static NSString * const C_AND_ARRIVE_POI_WAYPOINT = @"and_arrive_poi";
static NSString * const C_REACHED_WAYPOINT = @"reached_waypoint";
static NSString * const C_REACHED_FAVORITE = @"reached_favorite";
static NSString * const C_REACHED_POI = @"reached_poi";
static NSString * const C_THEN = @"then";
static NSString * const C_SPEAD_ALARM = @"speed_alarm";
static NSString * const C_ATTENTION = @"attention";
static NSString * const C_OFF_ROUTE = @"off_route";
static NSString * const C_BACK_ON_ROUTE = @"back_on_route";
static NSString * const C_TAKE_EXIT = @"take_exit";

static NSString * const C_BEAR_LEFT = @"bear_left";
static NSString * const C_BEAR_RIGHT = @"bear_right";
static NSString * const C_ROUTE_RECALC = @"route_recalc";
static NSString * const C_ROUTE_NEW_CALC = @"route_new_calc";
static NSString * const C_LOCATION_LOST = @"location_lost";
static NSString * const C_LOCATION_RECOVERED = @"location_recovered";

static NSString * const C_SET_METRICS = @"setMetricConst";
static NSString * const C_SET_MODE = @"setMode";

- (instancetype) initWithCommandPlayer:(id<OACommandPlayer>)player jsContext:(JSContext *) context
{
    self = [super init];
    if (self)
    {
        commandPlayer = player;
        alreadyExecuted = NO;
        listStruct = [NSMutableArray array];
        self->context = context;
    }
    return self;
}

- (void) checkState
{
    if (alreadyExecuted)
        @throw [NSException exceptionWithName:@"OACommandBuilder exception"
                                       reason:@"Check state: alreadyExecuted"
                                     userInfo:nil];
}

- (void) setParameters:(NSString *) metricConstant mode:(BOOL) tts
{
    [context[C_SET_METRICS] callWithArguments:@[metricConstant]];
    [context[C_SET_MODE] callWithArguments:@[@(YES)]];
}

- (BOOL) isJSCommandExsists:(NSString *)name
{
    return context[name] != nil;
}

- (OACommandBuilder *) addCommand:(NSString * _Nonnull)name
{
    [listStruct addObject:[[context[name] callWithArguments:@[]] toString]];
    return self;
}

- (OACommandBuilder *) addCommand:(NSString * _Nonnull)name args:(NSArray * _Nonnull)args
{
    [listStruct addObject:[[context[name] callWithArguments:args] toString]];
    return self;
}

- (OACommandBuilder *) goAhead
{
    return [self goAhead:-1 streetName: [NSMutableDictionary new]];
}

- (OACommandBuilder *) goAhead:(double)dist streetName:(id)streetName
{
    return [self addCommand:C_GO_AHEAD args:@[@(dist), streetName]];
}

- (OACommandBuilder *) makeUTwp
{
    return [self addCommand:C_MAKE_UTWP];
}

- (OACommandBuilder *) makeUT:(id)streetName
{
    return [self makeUT:-1 streetName:streetName];
}

- (OACommandBuilder *) makeUT:(double)dist streetName:(id)streetName
{
    return [self addCommand:C_MAKE_UT args:@[@(dist), streetName]];
}

- (OACommandBuilder *) speedAlarm:(int)maxSpeed speed:(float)speed
{
    return [self addCommand:C_SPEAD_ALARM args:@[@(maxSpeed), @(speed)]];
}

- (OACommandBuilder *) attention:(NSString *)type
{
    return [self addCommand:C_ATTENTION args:@[type]];
}

- (OACommandBuilder *) offRoute:(double)dist
{
    return [self addCommand:C_OFF_ROUTE args:@[@(dist)]];
}

- (OACommandBuilder *) backOnRoute
{
    return [self addCommand:C_BACK_ON_ROUTE];
}

- (OACommandBuilder *) prepareMakeUT:(double)dist streetName:(id)streetName
{
    return [self addCommand:C_PREPARE_MAKE_UT args:@[@(dist), streetName]];
}

- (OACommandBuilder *) turn:(NSString *)param streetName:(id)streetName
{
    return [self turn:param dist:-1 streetName:streetName];
}

- (OACommandBuilder *) turn:(NSString *)param dist:(double)dist streetName:(id)streetName
{
    return [self addCommand:C_TURN args:@[param, @(dist), streetName]];
}

- (OACommandBuilder *) takeExit:(NSString *)turnType exitString:(NSString *)exitString exitInt:(NSInteger)exitInt streetName:(id)streetName
{
    return [self takeExit:turnType dist:-1 exitString:exitString exitInt:exitInt streetName:streetName];
}

- (OACommandBuilder *) takeExit:(NSString *)turnType dist:(double)dist exitString:(NSString *)exitString exitInt:(NSInteger)exitInt streetName:(id)streetName
{
    return [self isJSCommandExsists:C_TAKE_EXIT] ?
        [self addCommand:C_TAKE_EXIT args:@[turnType, @(dist), exitString, @(exitInt), streetName]] :
        [self addCommand:C_TURN args:@[turnType, @(dist), streetName]];
}

/**
 *
 * @param param A_LEFT, A_RIGHT, ...
 * @param dist
 * @return
 */
- (OACommandBuilder *) prepareTurn:(NSString *)param dist:(double)dist streetName:(id)streetName
{
    return [self addCommand:C_PREPARE_TURN args:@[param, @(dist), streetName]];
}

- (OACommandBuilder *) prepareRoundAbout:(double)dist exit:(int)exit streetName:(id)streetName
{
    return [self addCommand:C_PREPARE_ROUNDABOUT args:@[@(dist), @(exit), streetName]];
}

- (OACommandBuilder *) roundAbout:(double)dist angle:(double)angle exit:(int)exit streetName:(id)streetName
{
    return [self addCommand:C_ROUNDABOUT args:@[@(dist), @(angle), @(exit), streetName]];
}

- (OACommandBuilder *) roundAbout:(double)angle exit:(int)exit streetName:(id)streetName
{
    return [self roundAbout:-1 angle:angle exit:exit streetName:streetName];
}

- (OACommandBuilder *) andArriveAtDestination:(NSString *)name
{
    return [self addCommand:C_AND_ARRIVE_DESTINATION args:@[name]];
}

- (OACommandBuilder *) arrivedAtDestination:(NSString *)name
{
    return [self addCommand:C_REACHED_DESTINATION args:@[name]];
}

- (OACommandBuilder *) andArriveAtIntermediatePoint:(NSString *)name
{
    return [self addCommand:C_AND_ARRIVE_INTERMEDIATE args:@[name]];
}

- (OACommandBuilder *) arrivedAtIntermediatePoint:(NSString *)name
{
    return [self addCommand:C_REACHED_INTERMEDIATE args:@[name]];
}

- (OACommandBuilder *) andArriveAtWayPoint:(NSString *)name
{
    return [self addCommand:C_AND_ARRIVE_WAYPOINT args:@[name]];
}

- (OACommandBuilder *) arrivedAtWayPoint:(NSString *)name
{
    return [self addCommand:C_REACHED_WAYPOINT args:@[name]];
}

- (OACommandBuilder *) andArriveAtFavorite:(NSString *)name
{
    return [self addCommand:C_AND_ARRIVE_FAVORITE args:@[name]];
}

- (OACommandBuilder *) arrivedAtFavorite:(NSString *)name
{
    return [self addCommand:C_REACHED_FAVORITE args:@[name]];
}

- (OACommandBuilder *) andArriveAtPoi:(NSString *)name
{
    return [self addCommand:C_AND_ARRIVE_POI_WAYPOINT args:@[name]];
}

- (OACommandBuilder *) arrivedAtPoi:(NSString *)name
{
    return [self addCommand:C_REACHED_POI args:@[name]];
}

- (OACommandBuilder *) bearLeft:(id)streetName
{
    return [self addCommand:C_BEAR_LEFT args:@[streetName]];
}

- (OACommandBuilder *) bearRight:(id)streetName
{
    return [self addCommand:C_BEAR_RIGHT args:@[streetName]];
}

- (OACommandBuilder *) then
{
    return [self addCommand:C_THEN args:@[]];
}

- (OACommandBuilder *) gpsLocationLost
{
    return [self addCommand:C_LOCATION_LOST];
}

- (OACommandBuilder *) gpsLocationRecover
{
    return [self addCommand:C_LOCATION_RECOVERED];
}

- (OACommandBuilder *) newRouteCalculated:(double)dist time:(long)time
{
    return [self addCommand:C_ROUTE_NEW_CALC args:@[@(dist), @(time)]];
}

- (OACommandBuilder *) routeRecalculated:(double)dist time:(long)time
{
    return [self addCommand:C_ROUTE_RECALC args:@[@(dist), @(time)]];
}

- (void) play
{
    [commandPlayer playCommands:self];
}


- (NSArray<NSString *> *) getUtterances
{
    alreadyExecuted = true;
    return listStruct;
}

@end
