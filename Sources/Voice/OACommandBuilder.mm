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

static NSString * const C_BEAR_LEFT = @"bear_left";
static NSString * const C_BEAR_RIGHT = @"bear_right";
static NSString * const C_ROUTE_RECALC = @"route_recalc";
static NSString * const C_ROUTE_NEW_CALC = @"route_new_calc";
static NSString * const C_LOCATION_LOST = @"location_lost";
static NSString * const C_LOCATION_RECOVERED = @"location_recovered";

static NSString * const C_SET_METRICS = @"setMetricConst";

- (instancetype) initWithCommandPlayer:(id<OACommandPlayer>)player
{
    self = [super init];
    if (self)
    {
        commandPlayer = player;
        alreadyExecuted = NO;
        listStruct = [NSMutableArray array];
        NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"en_tts" ofType:@"js"];
        context = [[JSContext alloc] init];
        NSString *scriptString = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        [context evaluateScript:scriptString];
        [context[C_SET_METRICS] callWithArguments:@[@"km-m"]];
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

- (id) prepareStruct:(NSString * _Nonnull)name
{
    return [self prepareStruct:name args:@[]];
}

- (id) prepareStruct:(NSString * _Nonnull)name args:(NSArray * _Nonnull)args
{
    [self checkState];
    NSMutableString *structure = [[NSMutableString alloc] init];
    [structure appendString:name];
    for (NSObject *obj in args) {
        if ([obj isKindOfClass:[NSNumber class]])
        {
            [structure appendString:[(NSNumber*) obj stringValue]];
        }
        else
        {
            [structure appendString:(NSString *) obj];
        }
    }
    /* TODO
    Term[] list = new Term[args.length];
    for (int i = 0; i < args.length; i++) {
        Object o = args[i];
        if(o instanceof Term){
            list[i] = (Term) o;
        } else if(o instanceof java.lang.Number){
            if(o instanceof java.lang.Double){
                list[i] = new alice.tuprolog.Double((Double) o);
            } else if(o instanceof java.lang.Float){
                list[i] = new alice.tuprolog.Float((Float) o);
            } else if(o instanceof java.lang.Long){
                list[i] = new alice.tuprolog.Long((Long) o);
            } else {
                list[i] = new alice.tuprolog.Int(((java.lang.Number)o).intValue);
            }
        } else if(o instanceof String){
            list[i] = new Struct((String) o);
        }
        if(o == null){
            list[i] = new Struct("");
        }
    }
    Struct struct = new Struct(name, list);
    if(log.isDebugEnabled){
        log.debug("Adding command : " + name + " " + Arrays.toString(args)); //$NON-NLS-1$ //$NON-NLS-2$
    }
     */
    // TODO parse the elements here and build an utterance
    [listStruct addObject:structure];
    return structure;
}

- (OACommandBuilder *) alt:(NSArray * _Nonnull)s1
{
    /* TODO
    if (s1.length == 1) {
        listStruct.add(s1[0]);
    } else {
        listStruct.add(new Struct(s1));
    }
    */
//    [listStruct addObject:[s1 componentsJoinedByString:@" "]];
    return self;
}

- (OACommandBuilder *) goAhead
{
    return [self goAhead: -1 streetName: nil];
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
    return [self alt:@[[self prepareStruct:C_MAKE_UT args:@[streetName]], @[[self prepareStruct:C_MAKE_UT]]]];
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

- (OACommandBuilder *) makeUT:(double)dist streetName:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_MAKE_UT args:@[@(dist), streetName]], [self prepareStruct:C_MAKE_UT args:@[@(dist)]]]];
}

- (OACommandBuilder *) prepareMakeUT:(double)dist streetName:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_PREPARE_MAKE_UT args:@[@(dist), streetName]], [self prepareStruct:C_PREPARE_MAKE_UT args:@[@(dist)]]]];
}

- (OACommandBuilder *) turn:(NSString *)param streetName:(id)streetName
{
    return [self turn:param dist:-1 streetName:streetName];
}

- (OACommandBuilder *) turn:(NSString *)param dist:(double)dist streetName:(id)streetName
{
    return [self addCommand:C_TURN args:@[param, @(dist), streetName]];
}

/**
 *
 * @param param A_LEFT, A_RIGHT, ...
 * @param dist
 * @return
 */
- (OACommandBuilder *) prepareTurn:(NSString *)param dist:(double)dist streetName:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_PREPARE_TURN args:@[param, @(dist), streetName]], [self prepareStruct:C_PREPARE_TURN args:@[param, @(dist)]]]];
}

- (OACommandBuilder *) prepareRoundAbout:(double)dist exit:(int)exit streetName:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_PREPARE_ROUNDABOUT args:@[@(dist), @(exit), streetName]], [self prepareStruct:C_PREPARE_ROUNDABOUT args:@[@(dist)]]]];
}

- (OACommandBuilder *) roundAbout:(double)dist angle:(double)angle exit:(int)exit streetName:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_ROUNDABOUT args:@[@(dist), @(angle), @(exit), streetName]], [self prepareStruct:C_ROUNDABOUT args:@[@(dist), @(angle), @(exit)]]]];
}

- (OACommandBuilder *) roundAbout:(double)angle exit:(int)exit streetName:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_ROUNDABOUT args:@[@(angle), @(exit), streetName]], [self prepareStruct:C_ROUNDABOUT args:@[@(angle), @(exit)]]]];
}

- (OACommandBuilder *) andArriveAtDestination:(NSString *)name
{
    return [self alt:@[[self prepareStruct:C_AND_ARRIVE_DESTINATION args:@[name]], [self prepareStruct:C_AND_ARRIVE_DESTINATION]]];
}

- (OACommandBuilder *) arrivedAtDestination:(NSString *)name
{
    return [self alt:@[[self prepareStruct:C_REACHED_DESTINATION args:@[name]], [self prepareStruct:C_REACHED_DESTINATION]]];
}

- (OACommandBuilder *) andArriveAtIntermediatePoint:(NSString *)name
{
    return [self alt:@[[self prepareStruct:C_AND_ARRIVE_INTERMEDIATE args:@[name]], [self prepareStruct:C_AND_ARRIVE_INTERMEDIATE]]];
}

- (OACommandBuilder *) arrivedAtIntermediatePoint:(NSString *)name
{
    return [self alt:@[[self prepareStruct:C_REACHED_INTERMEDIATE args:@[name]], [self prepareStruct:C_REACHED_INTERMEDIATE]]];
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
    return [self alt:@[[self prepareStruct:C_BEAR_LEFT args:@[streetName]], [self prepareStruct:C_BEAR_LEFT]]];
}

- (OACommandBuilder *) bearRight:(id)streetName
{
    return [self alt:@[[self prepareStruct:C_BEAR_RIGHT args:@[streetName]], [self prepareStruct:C_BEAR_RIGHT]]];
}

- (OACommandBuilder *) then
{
    return [self addCommand:C_THEN];
}

- (OACommandBuilder *) gpsLocationLost
{
    return [self addCommand:C_LOCATION_LOST];
}

- (OACommandBuilder *) gpsLocationRecover
{
    return [self addCommand:C_LOCATION_RECOVERED];
}

- (OACommandBuilder *) newRouteCalculated:(double)dist time:(int)time
{
    return [self addCommand:C_ROUTE_NEW_CALC args:@[@(dist), @(time), @"km-m"]];
}

- (OACommandBuilder *) routeRecalculated:(double)dist time:(int)time
{
    return [self addCommand:C_ROUTE_RECALC args:@[@(dist), @(time), @"km-m"]];
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
