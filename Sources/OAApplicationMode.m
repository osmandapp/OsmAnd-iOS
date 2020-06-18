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
static OAApplicationMode *_PUBLIC_TRANSPORT;
static OAApplicationMode *_PEDESTRIAN;
static OAApplicationMode *_AIRCRAFT;
static OAApplicationMode *_BOAT;
static OAApplicationMode *_SKI;

+ (void) initialize
{
    _widgetsVisibilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _widgetsAvailabilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _values = [NSMutableArray array];
    _cachedFilteredValues = [NSMutableArray array];
    
    _DEFAULT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_overview") stringKey:@"default"];
    [self defLocation:_DEFAULT];
    _DEFAULT.mapIcon = @"map_world_globe_dark";
    _DEFAULT.smallIconDark = @"ic_world_globe_dark";
    [_values addObject:_DEFAULT];
    
    _CAR = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_car") stringKey:@"car"];
    _CAR.descr = OALocalizedString(@"base_profile_descr_car");
    [self carLocation:_CAR];
    _CAR.mapIcon = @"map_action_car_dark";
    _CAR.smallIconDark = @"ic_action_car_dark";
    [_values addObject:_CAR];
    
    _BICYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_bicycle") stringKey:@"bicycle"];
    _BICYCLE.descr = OALocalizedString(@"base_profile_descr_bicycle");
    [self bicycleLocation:_BICYCLE];
    _BICYCLE.mapIcon = @"map_action_bicycle_dark";
    _BICYCLE.smallIconDark = @"ic_action_bicycle_dark";
    [_values addObject:_BICYCLE];
    
    _PEDESTRIAN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_walk") stringKey:@"pedestrian"];
    _PEDESTRIAN.descr = OALocalizedString(@"base_profile_descr_pedestrian");
    [self pedestrianLocation:_PEDESTRIAN];
    _PEDESTRIAN.mapIcon = @"map_action_pedestrian_dark";
    _PEDESTRIAN.smallIconDark = @"ic_action_pedestrian_dark";
    [_values addObject:_PEDESTRIAN];
    
    _PUBLIC_TRANSPORT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_pulic_transport") stringKey:@"public_transport"];
    _PUBLIC_TRANSPORT.descr = OALocalizedString(@"base_profile_descr_public_transport");
    _PUBLIC_TRANSPORT.defaultSpeed = 15.3f;
    [self carLocation:_PUBLIC_TRANSPORT];
    _PUBLIC_TRANSPORT.mapIcon = @"map_action_bus_dark";
    _PUBLIC_TRANSPORT.smallIconDark = @"ic_action_bus_dark";
    [_values addObject:_PUBLIC_TRANSPORT];
    
    _AIRCRAFT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_aircraft") stringKey:@"aircraft"];
    _AIRCRAFT.descr = OALocalizedString(@"base_profile_descr_aircraft");
    _AIRCRAFT.defaultSpeed = 40.0f;
    [self carLocation:_AIRCRAFT];
    _AIRCRAFT.mapIcon = @"map_action_aircraft";
    _AIRCRAFT.smallIconDark = @"ic_action_aircraft";
    [_values addObject:_AIRCRAFT];
    
    _BOAT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_boat") stringKey:@"boat"];
    _BOAT.descr = OALocalizedString(@"base_profile_descr_boat");
    _BOAT.defaultSpeed = 5.5f;
    [self carLocation:_BOAT];
    _BOAT.mapIcon = @"map_action_sail_boat_dark";
    _BOAT.smallIconDark = @"ic_action_sail_boat_dark";
    [_values addObject:_BOAT];
    
    _SKI = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_skiing") stringKey:@"ski"];
    _SKI.descr = OALocalizedString(@"app_mode_skiing");
    [self carLocation:_SKI];
    _SKI.mapIcon = @"map_action_skiing";
    _SKI.smallIconDark = @"ic_action_train";
    [_values addObject:_SKI];
    
    NSArray<OAApplicationMode *> *exceptDefault = @[_CAR, _PEDESTRIAN, _BICYCLE, _PUBLIC_TRANSPORT, _BOAT, _AIRCRAFT, _SKI];
    
    NSArray<OAApplicationMode *> *all = nil;
    NSArray<OAApplicationMode *> *none = @[];
    
    NSArray<OAApplicationMode *> *navigationSet1 = @[_CAR, _BICYCLE, _BOAT, _SKI];
    NSArray<OAApplicationMode *> *navigationSet2 = @[_PEDESTRIAN, _PUBLIC_TRANSPORT, _AIRCRAFT];
    
    // left
    [self regWidgetVisibility:@"next_turn" am:navigationSet1];;
    [self regWidgetVisibility:@"next_turn_small" am:navigationSet2];
    [self regWidgetVisibility:@"next_next_turn" am:navigationSet1];
    [self regWidgetAvailability:@"next_turn" am:exceptDefault];
    [self regWidgetAvailability:@"next_turn_small" am:exceptDefault];
    [self regWidgetAvailability:@"next_next_turn" am:exceptDefault];
    
    // right
    [self regWidgetVisibility:@"intermediate_distance" am:all];
    [self regWidgetVisibility:@"distance" am:all];
    [self regWidgetVisibility:@"time" am:all];
    [self regWidgetVisibility:@"intermediate_time" am:all];
    [self regWidgetVisibility:@"speed" am:@[_CAR, _BICYCLE, _BOAT, _SKI, _PUBLIC_TRANSPORT, _AIRCRAFT]];
    [self regWidgetVisibility:@"max_speed" am:@[_CAR]];
    [self regWidgetVisibility:@"altitude" am:@[_PEDESTRIAN, _BICYCLE]];
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
    [self regWidgetVisibility:@"street_name" am:@[_CAR, _BICYCLE, _PEDESTRIAN, _PUBLIC_TRANSPORT]];
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

+ (OAApplicationMode *) PUBLIC_TRANSPORT
{
    return _PUBLIC_TRANSPORT;
}

+ (OAApplicationMode *) SKI
{
    return _SKI;
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

- (NSInteger) getOffRouteDistance
{
    // used to be: 50/14 - 350 m, 10/2.7 - 50 m, 4/1.11 - 20 m
    double speed = MAX(_defaultSpeed, 0.3f);
    // become: 50 kmh - 280 m, 10 kmh - 55 m, 4 kmh - 22 m
    return (NSInteger) (speed * 20);
}

- (NSInteger) getMinDistanceForTurn
{
    // used to be: 50 kmh - 35 m, 10 kmh - 15 m, 4 kmh - 5 m, 10 kmh - 20 m, 400 kmh - 100 m,
    float speed = MAX([self getDefaultSpeed], 0.3f);
    // 2 sec + 7 m: 50 kmh - 35 m, 10 kmh - 12 m, 4 kmh - 9 m, 400 kmh - 230 m
    return (int) (7 + speed * 2);
}

- (NSInteger) getDefaultSpeed
{
    // TODO: Change this method after syncing the settings with Android
    return _defaultSpeed;
}

+ (OAApplicationMode *) valueOfStringKey:(NSString *)key def:(OAApplicationMode *)def
{
    for (OAApplicationMode *p in _values)
        if ([p.stringKey isEqualToString:key])
            return p;

    return def;
}

- (BOOL) isDerivedRoutingFrom:(OAApplicationMode *)mode
{
    return self == mode || _parent == mode;
}

- (NSString *) getRoutingProfile
{
    return [OAAppSettings.sharedManager.routingProfile get:self];
}

- (void) setRoutingProfile:(NSString *) routingProfile
{
    if (routingProfile.length > 0)
        [OAAppSettings.sharedManager.routingProfile set:routingProfile mode:self];
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
