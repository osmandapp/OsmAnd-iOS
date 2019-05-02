//
//  OAApplicationMode.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"

@interface OAApplicationMode ()

@property (nonatomic) NSInteger modeId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *stringKey;
@property (nonatomic) NSString *variantKey;

@property (nonatomic) OAApplicationMode *parent;

@property (nonatomic) float defaultSpeed;
@property (nonatomic) int minDistanceForTurn;
@property (nonatomic) int arrivalDistance;

@property (nonatomic) NSString *mapIcon;
@property (nonatomic) NSString *smallIconDark;
@property (nonatomic) NSString *bearingIconDay;
@property (nonatomic) NSString *bearingIconNight;
@property (nonatomic) NSString *headingIconDay;
@property (nonatomic) NSString *headingIconNight;
@property (nonatomic) NSString *locationIconDay;
@property (nonatomic) NSString *locationIconNight;
@property (nonatomic) NSString *locationIconDayLost;
@property (nonatomic) NSString *locationIconNightLost;

@end

@implementation OAApplicationMode

static NSMapTable<NSString *, NSMutableSet<OAApplicationMode *> *> *_widgetsVisibilityMap;
static NSMapTable<NSString *, NSMutableSet<OAApplicationMode *> *> *_widgetsAvailabilityMap;
static NSMutableArray<OAApplicationMode *> *_values;
static NSMutableArray<OAApplicationMode *> *_cachedFilteredValues;
static OAAutoObserverProxy* _listener;


static OAApplicationMode *_DEFAULT;
static OAApplicationMode *_CAR;
static OAApplicationMode *_BICYCLE;
static OAApplicationMode *_PEDESTRIAN;
static OAApplicationMode *_AIRCRAFT;
static OAApplicationMode *_BOAT;
static OAApplicationMode *_HIKING;
static OAApplicationMode *_MOTORCYCLE;
static OAApplicationMode *_TRUCK;
static OAApplicationMode *_BUS;
static OAApplicationMode *_TRAIN;

+ (void) initialize
{
    _widgetsVisibilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _widgetsAvailabilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _values = [NSMutableArray array];
    _cachedFilteredValues = [NSMutableArray array];
    
    _DEFAULT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_overview") stringKey:@"default"];
    _DEFAULT.modeId = 1;
    _DEFAULT.defaultSpeed = 1.5f;
    _DEFAULT.minDistanceForTurn = 5;
    _DEFAULT.arrivalDistance = 90;
    [self defLocation:_DEFAULT];
    _DEFAULT.mapIcon = @"map_world_globe_dark";
    _DEFAULT.smallIconDark = @"ic_action_world_globe";
    [_values addObject:_DEFAULT];
    
    _CAR = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_car") stringKey:@"car"];
    _CAR.modeId = 2;
    _CAR.defaultSpeed = 15.3f;
    _CAR.minDistanceForTurn = 35;
    [self carLocation:_CAR];
    _CAR.mapIcon = @"map_action_car_dark";
    _CAR.smallIconDark = @"ic_action_car_dark";
    [_values addObject:_CAR];
    
    _BICYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_bicycle") stringKey:@"bicycle"];
    _BICYCLE.modeId = 3;
    _BICYCLE.defaultSpeed = 5.5f;
    _BICYCLE.minDistanceForTurn = 15;
    _BICYCLE.arrivalDistance = 60;
    [self bicycleLocation:_BICYCLE];
    _BICYCLE.mapIcon = @"map_action_bicycle_dark";
    _BICYCLE.smallIconDark = @"ic_action_bicycle_dark";
    [_values addObject:_BICYCLE];
    
    _PEDESTRIAN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_walk") stringKey:@"pedestrian"];
    _PEDESTRIAN.modeId = 4;
    _PEDESTRIAN.defaultSpeed = 1.5f;
    _PEDESTRIAN.minDistanceForTurn = 5;
    _PEDESTRIAN.arrivalDistance = 45;
    [self pedestrianLocation:_PEDESTRIAN];
    _PEDESTRIAN.mapIcon = @"map_action_pedestrian_dark";
    _PEDESTRIAN.smallIconDark = @"ic_action_pedestrian_dark";
    [_values addObject:_PEDESTRIAN];
    
    _AIRCRAFT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_aircraft") stringKey:@"aircraft"];
    _AIRCRAFT.modeId = 5;
    _AIRCRAFT.defaultSpeed = 40.0f;
    _AIRCRAFT.minDistanceForTurn = 100;
    [self carLocation:_AIRCRAFT];
    _AIRCRAFT.mapIcon = @"map_action_aircraft";
    _AIRCRAFT.smallIconDark = @"ic_action_aircraft";
    [_values addObject:_AIRCRAFT];
    
    _BOAT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_boat") stringKey:@"boat"];
    _BOAT.modeId = 6;
    _BOAT.defaultSpeed = 5.5f;
    _BOAT.minDistanceForTurn = 20;
    [self carLocation:_BOAT];
    _BOAT.mapIcon = @"map_action_sail_boat_dark";
    _BOAT.smallIconDark = @"ic_action_sail_boat_dark";
    [_values addObject:_BOAT];

    _HIKING = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_hiking") stringKey:@"hiking"];
    _HIKING.modeId = 7;
    _HIKING.defaultSpeed = 1.5f;
    _HIKING.minDistanceForTurn = 5;
    [self pedestrianLocation:_HIKING];
    _HIKING.mapIcon = @"map_action_trekking_dark";
    _HIKING.smallIconDark = @"ic_action_trekking_dark";
    _HIKING.parent = _PEDESTRIAN;
    [_values addObject:_HIKING];
    
    _MOTORCYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_motorcycle") stringKey:@"motorcycle"];
    _MOTORCYCLE.modeId = 8;
    _MOTORCYCLE.defaultSpeed = 15.3f;
    _MOTORCYCLE.minDistanceForTurn = 40;
    [self carLocation:_MOTORCYCLE];
    _MOTORCYCLE.mapIcon = @"map_action_motorcycle_dark";
    _MOTORCYCLE.smallIconDark = @"ic_action_motorcycle_dark";
    _MOTORCYCLE.parent = _CAR;
    [_values addObject:_MOTORCYCLE];
    
    _TRUCK = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_truck") stringKey:@"truck"];
    _TRUCK.modeId = 9;
    _TRUCK.defaultSpeed = 15.3f;
    _TRUCK.minDistanceForTurn = 40;
    [self carLocation:_TRUCK];
    _TRUCK.mapIcon = @"map_action_truck_dark";
    _TRUCK.smallIconDark = @"ic_action_truck_dark";
    _TRUCK.parent = _CAR;
    [_values addObject:_TRUCK];
    
    _BUS = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_bus") stringKey:@"bus"];
    _BUS.modeId = 10;
    _BUS.defaultSpeed = 15.3f;
    _BUS.minDistanceForTurn = 40;
    [self carLocation:_BUS];
    _BUS.mapIcon = @"map_action_bus_dark";
    _BUS.smallIconDark = @"ic_action_bus_dark";
    _BUS.parent = _CAR;
    [_values addObject:_BUS];
    
    _TRAIN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_train") stringKey:@"train"];
    _TRAIN.modeId = 11;
    _TRAIN.defaultSpeed = 25.0f;
    _TRAIN.minDistanceForTurn = 40;
    [self carLocation:_TRAIN];
    _TRAIN.mapIcon = @"map_action_train";
    _TRAIN.smallIconDark = @"ic_action_train";
    _TRAIN.parent = _CAR;
    [_values addObject:_TRAIN];
    
    NSArray<OAApplicationMode *> *exceptDefault = @[_CAR, _PEDESTRIAN, _BICYCLE, _BOAT, _AIRCRAFT, _BUS, _TRAIN];
    NSArray<OAApplicationMode *> *exceptPedestrianAndDefault = @[_CAR, _BICYCLE, _BOAT, _AIRCRAFT, _BUS, _TRAIN];
    NSArray<OAApplicationMode *> *exceptAirBoatDefault = @[_CAR, _BICYCLE, _PEDESTRIAN];
    NSArray<OAApplicationMode *> *pedestrian = @[_PEDESTRIAN];
    NSArray<OAApplicationMode *> *pedestrianBicycle = @[_PEDESTRIAN, _BICYCLE];
    
    NSArray<OAApplicationMode *> *all = nil;
    NSArray<OAApplicationMode *> *none = @[];
    
    // left
    [self regWidgetVisibility:@"next_turn" am:exceptPedestrianAndDefault];;
    [self regWidgetVisibility:@"next_turn_small" am:pedestrian];
    [self regWidgetVisibility:@"next_next_turn" am:exceptPedestrianAndDefault];
    [self regWidgetAvailability:@"next_turn" am:exceptDefault];
    [self regWidgetAvailability:@"next_turn_small" am:exceptDefault];
    [self regWidgetAvailability:@"next_next_turn" am:exceptDefault];
    
    // right
    [self regWidgetVisibility:@"intermediate_distance" am:all];
    [self regWidgetVisibility:@"distance" am:all];
    [self regWidgetVisibility:@"time" am:all];
    [self regWidgetVisibility:@"intermediate_time" am:all];
    [self regWidgetVisibility:@"speed" am:exceptPedestrianAndDefault];
    [self regWidgetVisibility:@"max_speed" am:@[_CAR]];
    [self regWidgetVisibility:@"altitude" am:pedestrianBicycle];
    [self regWidgetVisibility:@"gps_info" am:none];
    
    [self regWidgetAvailability:@"intermediate_distance" am:all];
    [self regWidgetAvailability:@"distance" am:all];
    [self regWidgetAvailability:@"time" am:all];
    [self regWidgetAvailability:@"intermediate_time" am:all];
    [self regWidgetAvailability:@"map_marker_1st" am:none];
    [self regWidgetAvailability:@"map_marker_2nd" am:none];
    
    // top
    [self regWidgetVisibility:@"config" am:none];
    [self regWidgetVisibility:@"layers" am:none];
    [self regWidgetVisibility:@"compass" am:none];
    [self regWidgetVisibility:@"street_name" am:exceptAirBoatDefault];
    [self regWidgetVisibility:@"back_to_location" am:all];
    [self regWidgetVisibility:@"monitoring_services" am:none];
    [self regWidgetVisibility:@"bgService" am:none];
}

+ (OAApplicationMode *) DEFAULT
{
    return _DEFAULT;
}

+ (OAApplicationMode *) CAR
{
    return _CAR;
}

+ (OAApplicationMode *) BICYCLE;
{
    return _BICYCLE;
}

+ (OAApplicationMode *) PEDESTRIAN;
{
    return _PEDESTRIAN;
}

+ (OAApplicationMode *) AIRCRAFT;
{
    return _AIRCRAFT;
}

+ (OAApplicationMode *) BOAT;
{
    return _BOAT;
}

+ (OAApplicationMode *) HIKING;
{
    return _HIKING;
}

+ (OAApplicationMode *) MOTORCYCLE;
{
    return _MOTORCYCLE;
}

+ (OAApplicationMode *) TRUCK;
{
    return _TRUCK;
}

+ (OAApplicationMode *) BUS;
{
    return _BUS;
}

+ (OAApplicationMode *) TRAIN;
{
    return _TRAIN;
}

+ (void) carLocation:(OAApplicationMode *)applicationMode
{
    applicationMode.bearingIconDay = @"map_car_bearing";
    applicationMode.bearingIconNight = @"map_car_bearing_night";
    applicationMode.headingIconDay = @"map_car_location_view_angle";
    applicationMode.headingIconNight = @"map_car_location_view_angle_night";
    applicationMode.locationIconDay = @"map_car_location";
    applicationMode.locationIconNight = @"map_car_location_night";
    applicationMode.locationIconDayLost = @"map_car_location_lost";
    applicationMode.locationIconNightLost = @"map_car_location_lost_night";
}

+ (void) bicycleLocation:(OAApplicationMode *)applicationMode
{
    applicationMode.bearingIconDay = @"map_bicycle_bearing";
    applicationMode.bearingIconNight = @"map_bicycle_bearing_night";
    applicationMode.headingIconDay = @"map_bicycle_location_view_angle";
    applicationMode.headingIconNight = @"map_bicycle_location_view_angle_night";
    applicationMode.locationIconDay = @"map_bicycle_location";
    applicationMode.locationIconNight = @"map_bicycle_location_night";
    applicationMode.locationIconDayLost = @"map_bicycle_location_lost";
    applicationMode.locationIconNightLost = @"map_bicycle_location_lost_night";
}

+ (void) pedestrianLocation:(OAApplicationMode *)applicationMode
{
    applicationMode.bearingIconDay = @"map_pedestrian_bearing";
    applicationMode.bearingIconNight = @"map_pedestrian_bearing_night";
    applicationMode.headingIconDay = @"map_pedestrian_location_view_angle";
    applicationMode.headingIconNight = @"map_pedestrian_location_view_angle_night";
    applicationMode.locationIconDay = @"map_pedestrian_location";
    applicationMode.locationIconNight = @"map_pedestrian_location_night";
    applicationMode.locationIconDayLost = @"map_pedestrian_location_lost";
    applicationMode.locationIconNightLost = @"map_pedestrian_location_lost_night";
}

+ (void) defLocation:(OAApplicationMode *)applicationMode
{
    applicationMode.bearingIconDay = @"map_pedestrian_bearing";
    applicationMode.bearingIconNight = @"map_pedestrian_bearing_night";
    applicationMode.headingIconDay = @"map_default_location_view_angle";
    applicationMode.headingIconNight = @"map_default_location_view_angle_night";
    applicationMode.locationIconDay = @"map_pedestrian_location";
    applicationMode.locationIconNight = @"map_pedestrian_location_night";
    applicationMode.locationIconDayLost = @"map_pedestrian_location_lost";
    applicationMode.locationIconNightLost = @"map_pedestrian_location_lost_night";
}

- (instancetype)initWithName:(NSString *)name stringKey:(NSString *)stringKey
{
    self = [super init];
    if (self)
    {
        _name = name;
        _stringKey = stringKey;
        _variantKey = [NSString stringWithFormat:@"type_%@", stringKey];
        
        _defaultSpeed = 10.0f;
        _minDistanceForTurn = 50;
        _arrivalDistance = 90;
    }
    return self;
}

+ (NSArray<OAApplicationMode *> *) values
{
    if (_cachedFilteredValues.count == 0)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if (!_listener)
        {
            _listener = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onAvailableAppModesChanged)
                                                   andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
        }
        NSString *available = settings.availableApplicationModes;
        _cachedFilteredValues = [NSMutableArray array];
        for (OAApplicationMode *v in _values)
            if ([available containsString:[v.stringKey stringByAppendingString:@","]] || v == _DEFAULT)
                [_cachedFilteredValues addObject:v];
    }
    return [NSArray arrayWithArray:_cachedFilteredValues];
}

- (void) onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _cachedFilteredValues = [NSMutableArray array];
    });
}

+ (NSArray<OAApplicationMode *> *) allPossibleValues
{
    return [NSArray arrayWithArray:_values];
}

+ (NSArray<OAApplicationMode *> *) getModesDerivedFrom:(OAApplicationMode *)am
{
    NSMutableArray<OAApplicationMode *> *list = [NSMutableArray array];
    for (OAApplicationMode *a in _values)
        if (a == am || a.parent == am)
            [list addObject:a];

    return list;
}

- (BOOL) hasFastSpeed
{
    return _defaultSpeed > 10;
}

+ (OAApplicationMode *) valueOfStringKey:(NSString *)key def:(OAApplicationMode *)def
{
    for (OAApplicationMode *p in _values)
        if ([p.stringKey isEqualToString:key])
            return p;

    return def;
}

+ (OAApplicationMode *) getAppModeById:(NSInteger)modeId def:(OAApplicationMode *)def
{
    for (OAApplicationMode *p in _values)
        if (p.modeId == modeId)
            return p;
    
    return def;
}

- (BOOL) isDerivedRoutingFrom:(OAApplicationMode *)mode
{
    return self == mode || _parent == mode;
}

// returns modifiable ! Set<ApplicationMode> to exclude non-wanted derived
+ (NSSet<OAApplicationMode *> *) regWidgetVisibility:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am
{
    NSMutableSet<OAApplicationMode *> *set = [NSMutableSet set];
    if (!am)
        [set addObjectsFromArray:_values];
    else
        [set addObjectsFromArray:am];
    
    for (OAApplicationMode *m in _values)
    {
        // add derived modes
        if ([set containsObject:m.parent])
            [set addObject:m];
    }
    [_widgetsVisibilityMap setObject:set forKey:widgetId];
    return set;
}

- (BOOL) isWidgetCollapsible:(NSString *)key
{
    return false;
}

- (BOOL) isWidgetVisible:(NSString *)key
{
    NSSet<OAApplicationMode *> *set = [_widgetsVisibilityMap objectForKey:key];
    if (!set)
        return false;
    
    return [set containsObject:self];
}

+ (NSSet<OAApplicationMode *> *) regWidgetAvailability:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am
{
    NSMutableSet<OAApplicationMode *> *set = [NSMutableSet set];
    if (!am)
        [set addObjectsFromArray:_values];
    else
        [set addObjectsFromArray:am];
    
    for (OAApplicationMode *m in _values)
        // add derived modes
        if ([set containsObject:m.parent])
            [set addObject:m];
        
    [_widgetsAvailabilityMap setObject:set forKey:widgetId];
    return set;
}

- (BOOL) isWidgetAvailable:(NSString *)key
{
    NSSet<OAApplicationMode *> *set = [_widgetsAvailabilityMap objectForKey:key];
    if (!set)
        return true;
    
    return [set containsObject:self];
}

@end
