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
#import "OAColors.h"

@interface OAApplicationMode ()

@property (nonatomic) NSInteger modeId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *stringKey;
@property (nonatomic) NSString *variantKey;

@property (nonatomic) OAApplicationMode *parent;

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

+ (void)initRegVisibility
{
    NSArray<OAApplicationMode *> *exceptDefault = @[_CAR, _PEDESTRIAN, _BICYCLE, _PUBLIC_TRANSPORT, _BOAT, _AIRCRAFT, _SKI];
    
    NSArray<OAApplicationMode *> *all = nil;
    NSArray<OAApplicationMode *> *none = @[];
    
    NSArray<OAApplicationMode *> *navigationSet1 = @[_CAR, _BICYCLE, _BOAT, _SKI    ];
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

+ (void) initialize
{
    _widgetsVisibilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _widgetsAvailabilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _values = [NSMutableArray array];
    _cachedFilteredValues = [NSMutableArray array];
    
    _DEFAULT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"rendering_value_browse_map_name") stringKey:@"default"];
    _DEFAULT.descr = OALocalizedString(@"profile_type_base_string");
    [_values addObject:_DEFAULT];
    
    _CAR = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_car") stringKey:@"car"];
    _CAR.descr = OALocalizedString(@"base_profile_descr_car");
    _CAR.baseMinSpeed = 2.78;
    _CAR.baseMaxSpeed = 54.17;
    [_values addObject:_CAR];
    
    _BICYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_bicycle") stringKey:@"bicycle"];
    _BICYCLE.descr = OALocalizedString(@"base_profile_descr_bicycle");
    _BICYCLE.baseMinSpeed = 0.7;
    _BICYCLE.baseMaxSpeed = 13.76;
    [_values addObject:_BICYCLE];
    
    _PEDESTRIAN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_walk") stringKey:@"pedestrian"];
    _PEDESTRIAN.descr = OALocalizedString(@"base_profile_descr_pedestrian");
    _PEDESTRIAN.baseMinSpeed = 0.28;
    _PEDESTRIAN.baseMaxSpeed = 4.16;
    [_values addObject:_PEDESTRIAN];
    
    _PUBLIC_TRANSPORT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_pulic_transport") stringKey:@"public_transport"];
    _PUBLIC_TRANSPORT.descr = OALocalizedString(@"base_profile_descr_public_transport");
    _PUBLIC_TRANSPORT.baseMinSpeed = 0.28;
    _PUBLIC_TRANSPORT.baseMaxSpeed = 41.66;
    [_values addObject:_PUBLIC_TRANSPORT];
    
    _AIRCRAFT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_aircraft") stringKey:@"aircraft"];
    _AIRCRAFT.descr = OALocalizedString(@"base_profile_descr_aircraft");
    _AIRCRAFT.baseMinSpeed = 1.;
    _AIRCRAFT.baseMaxSpeed = 300.;
    [_values addObject:_AIRCRAFT];
    
    _BOAT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_boat") stringKey:@"boat"];
    _BOAT.descr = OALocalizedString(@"base_profile_descr_boat");
    _BOAT.baseMinSpeed = 0.42;
    _BOAT.baseMaxSpeed = 8.33;
    [_values addObject:_BOAT];
    
    _SKI = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_skiing") stringKey:@"ski"];
    _SKI.descr = OALocalizedString(@"app_mode_skiing");
    _SKI.baseMinSpeed = 0.42;
    _SKI.baseMaxSpeed = 62.5;
    [_values addObject:_SKI];
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

+ (OAApplicationMode *) buildApplicationModeByKey:(NSString *)key
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    OAApplicationMode *m = [[OAApplicationMode alloc] initWithName:@"" stringKey:key];
//    m.name = [settings.userProfileName get:m];
    m.parent = [self valueOfStringKey:[settings.parentAppMode get:m] def:nil];
    return m;
}

+ (OAApplicationModeBuilder *) fromModeBean:(OAApplicationModeBean *)modeBean
{
    OAApplicationModeBuilder *builder = [OAApplicationMode createCustomMode:[OAApplicationMode valueOfStringKey:modeBean.parent def:nil] stringKey:modeBean.stringKey];
    [builder setUserProfileName:modeBean.userProfileName];
    [builder setIconResName:modeBean.iconName];
    [builder setIconColor:modeBean.iconColor];
    [builder setRoutingProfile:modeBean.routingProfile];
    [builder setRouteService:modeBean.routeService];
    [builder setLocationIcon:modeBean.locIcon];
    [builder setNavigationIcon:modeBean.navIcon];
    [builder setOrder:modeBean.order];
    return builder;
}

- (instancetype)initWithName:(NSString *)name stringKey:(NSString *)stringKey
{
    self = [super init];
    if (self)
    {
        _name = name;
        _stringKey = stringKey;
        _variantKey = [NSString stringWithFormat:@"type_%@", stringKey];
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
        NSString *available = settings.availableApplicationModes.get;
        _cachedFilteredValues = [NSMutableArray array];
        for (OAApplicationMode *v in _values)
        {
            if ([available containsString:[v.stringKey stringByAppendingString:@","]] || v == _DEFAULT)
                [_cachedFilteredValues addObject:v];
        }
    }
    return [NSArray arrayWithArray:_cachedFilteredValues];
}

+ (void) onAvailableAppModesChanged
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

- (NSDictionary *) toJson
{
    return @{
        @"stringKey" : self.stringKey,
        @"userProfileName" : self.getUserProfileName,
        @"iconColor" : self.getIconColorName,
        @"iconName" : self.getIconName,
        @"parent" : self.parent ? self.parent.stringKey : @"",
        @"routeService" : self.getRouterServiceName,
        @"routingProfile" : self.getRoutingProfile,
        @"locIcon" : self.getLocationIconName,
        @"navIcon" : self.getNavigationIconName,
        @"order" : @(self.getOrder)
    };
}

- (BOOL) hasFastSpeed
{
    return [self getDefaultSpeed] > 10;
}

- (NSInteger) getOffRouteDistance
{
    // used to be: 50/14 - 350 m, 10/2.7 - 50 m, 4/1.11 - 20 m
    double speed = MAX([self getDefaultSpeed], 0.3f);
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

- (NSString *) toHumanString
{
    NSString *userProfileName = [self getUserProfileName];
    if (userProfileName.length == 0)
    {
        if (_name.length > 0)
            return _name;
        else
            return _stringKey.capitalizedString;
    }
    else
    {
        return userProfileName;
    }
}

- (BOOL) isCustomProfile
{
    return _parent != nil;
}

- (OAApplicationMode *) getParent
{
    return _parent ? _parent : [OAApplicationMode buildApplicationModeByKey:[OAAppSettings.sharedManager.parentAppMode get:self]];
}

- (void) setParent:(OAApplicationMode *)parent
{
    _parent = parent;
    [OAAppSettings.sharedManager.parentAppMode set:parent.stringKey mode:self];
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:self.getIconName];
}

- (NSString *) getIconName
{
    return [OAAppSettings.sharedManager.profileIconName get:self];
}

- (void) setIconName:(NSString *)iconName
{
    return [OAAppSettings.sharedManager.profileIconName set:iconName mode:self];
}

- (double) getDefaultSpeed
{
    return [OAAppSettings.sharedManager.defaultSpeed get:self];
}

- (void) setDefaultSpeed:(double) defaultSpeed
{
    [OAAppSettings.sharedManager.defaultSpeed set:defaultSpeed mode:self];
}

- (void) resetDefaultSpeed
{
    [OAAppSettings.sharedManager.defaultSpeed resetModeToDefault:self];
}

- (double) getMinSpeed
{
    return [OAAppSettings.sharedManager.minSpeed get:self];
}

- (void) setMinSpeed:(double) minSpeed
{
    [OAAppSettings.sharedManager.minSpeed set:minSpeed mode:self];
}

- (double) getMaxSpeed
{
    return [OAAppSettings.sharedManager.maxSpeed get:self];
}

- (void) setMaxSpeed:(double) maxSpeed
{
    [OAAppSettings.sharedManager.maxSpeed set:maxSpeed mode:self];
}

- (double) getStrAngle
{
    return [OAAppSettings.sharedManager.routeStraightAngle get:self];
}

- (void) setStrAngle:(double) straightAngle
{
    [OAAppSettings.sharedManager.routeStraightAngle set:straightAngle mode:self];
}

- (NSString *) getUserProfileName
{
    return [OAAppSettings.sharedManager.userProfileName get:self];
}

- (void) setUserProfileName:(NSString *)userProfileName
{
    if (userProfileName.length > 0)
        [OAAppSettings.sharedManager.userProfileName set:userProfileName mode:self];
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

- (NSString *) getRouterServiceName
{
    switch (self.getRouterService)
    {
        case OSMAND:
            return @"OSMAND";
        case DIRECT_TO:
            return @"DIRECT_TO";
        case STRAIGHT:
            return @"STRAIGHT";
        default:
            return @"OSMAND";
    }
}

- (NSInteger) getRouterService
{
    return [OAAppSettings.sharedManager.routerService get:self];
}

- (void) setRouterService:(NSInteger)routerService
{
    [OAAppSettings.sharedManager.routerService set:(int) routerService mode:self];
}

- (NSString *) getNavigationIconName
{
    switch (self.getNavigationIcon)
    {
        case NAVIGATION_ICON_DEFAULT:
            return @"DEFAULT";
        case NAVIGATION_ICON_NAUTICAL:
            return @"NAUTICAL";
        case NAVIGATION_ICON_CAR:
            return @"CAR";
        default:
            return @"DEFAULT";
    }
}

- (EOANavigationIcon) getNavigationIcon
{
    return [OAAppSettings.sharedManager.navigationIcon get:self];
}

- (void) setNavigationIcon:(EOANavigationIcon) navIcon
{
    [OAAppSettings.sharedManager.navigationIcon set:(int)navIcon mode:self];
}

- (NSString *) getLocationIconName
{
    switch (self.getLocationIcon)
    {
        case LOCATION_ICON_DEFAULT:
            return @"DEFAULT";
        case LOCATION_ICON_CAR:
            return @"CAR";
        case LOCATION_ICON_BICYCLE:
            return @"BICYCLE";
        default:
            return @"DEFAULT";
    }
}

- (EOALocationIcon) getLocationIcon
{
    return [OAAppSettings.sharedManager.locationIcon get:self];
}

- (void) setLocationIcon:(EOALocationIcon) locIcon
{
    [OAAppSettings.sharedManager.locationIcon set:(int)locIcon mode:self];
}

- (NSString *) getIconColorName
{
    switch (self.getIconColor)
    {
        case profile_icon_color_blue_light_default:
            return @"DEFAULT";
        case profile_icon_color_purple_light:
            return @"PURPLE";
        case profile_icon_color_green_light:
            return @"GREEN";
        case profile_icon_color_blue_light:
            return @"BLUE";
        case profile_icon_color_red_light:
            return @"RED";
        case profile_icon_color_yellow_light:
            return @"DARK_YELLOW";
        case profile_icon_color_magenta_light:
            return @"MAGENTA";
        default:
            return @"DEFAULT";
    }
}

- (int) getIconColor
{
    return [OAAppSettings.sharedManager.profileIconColor get:self];
}

- (void) setIconColor:(int)iconColor
{
    [OAAppSettings.sharedManager.profileIconColor set:iconColor mode:self];
}

- (int) getOrder
{
    return [OAAppSettings.sharedManager.appModeOrder get:self];
}

- (void) setOrder:(int)order
{
    [OAAppSettings.sharedManager.appModeOrder set:order mode:self];
}

- (NSString *) getProfileDescription
{
    return _descr && _descr.length > 0 ? _descr : OALocalizedString(@"profile_type_custom_string");
}

- (OAApplicationModeBean *) toModeBean
{
    return [OAApplicationModeBean fromJson:self.toJson];
}

+ (void) onApplicationStart
{
    [self initCustomModes];
//    [self initModesParams];
    [self initRegVisibility];
    [self reorderAppModes];
    [OAAppSettings.sharedManager setupAppMode];
}

+ (void) initCustomModes
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if (settings.customAppModes.get.length == 0)
        return;
    
    for (NSString *appModeKey in [settings getCustomAppModesKeys])
    {
        OAApplicationMode *m = [OAApplicationMode buildApplicationModeByKey:appModeKey];
        [_values addObject:m];
    }
}

+ (NSComparisonResult) compareModes:(OAApplicationMode *)obj1 obj2:(OAApplicationMode *) obj2
{
    return (obj1.getOrder < obj2.getOrder) ? NSOrderedAscending : ((obj1.getOrder == obj2.getOrder) ? NSOrderedSame : NSOrderedDescending);
}

+ (void) reorderAppModes
{
    [_values sortUsingComparator:^NSComparisonResult(OAApplicationMode *obj1, OAApplicationMode *obj2) {
        return [self compareModes:obj1 obj2:obj2];
    }];
    [_cachedFilteredValues sortUsingComparator:^NSComparisonResult(OAApplicationMode *obj1, OAApplicationMode *obj2) {
        return [self compareModes:obj1 obj2:obj2];
    }];

    [self updateAppModesOrder];
}

+ (void) updateAppModesOrder
{
    for (int i = 0; i < _values.count; i++)
    {
        [_values[i] setOrder:i];
    }
}

+ (void) saveCustomAppModesToSettings
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSMutableString *res = [[NSMutableString alloc] init];
    
    NSArray<OAApplicationMode *> * modes = [self getCustomAppModes];
    [modes enumerateObjectsUsingBlock:^(OAApplicationMode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [res appendString:obj.stringKey];
        if (idx != modes.count - 1)
            [res appendString:@","];
    }];
    
    if (![res isEqualToString:settings.customAppModes.get])
        [settings.customAppModes set:res];
}

+ (NSArray<OAApplicationMode *> *) getCustomAppModes
{
    NSMutableArray<OAApplicationMode *> *customModes = [NSMutableArray new];
    for (OAApplicationMode *mode in _values)
    {
        if (mode.isCustomProfile)
            [customModes addObject:mode];
        
    }
    return customModes;
}

+ (OAApplicationMode *) saveProfile:(OAApplicationModeBuilder *)builder
{
    OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:builder.am.stringKey def:nil];
    if (mode != nil)
    {
        [mode setParent:builder.am.parent];
        [mode setUserProfileName:builder.userProfileName];
        [mode setIconName:builder.iconResName];
        [mode setRoutingProfile:builder.routingProfile];
        [mode setRouterService:builder.routeService];
        [mode setIconColor:(int)builder.iconColor];
        [mode setLocationIcon:builder.locationIcon];
        [mode setNavigationIcon:builder.navigationIcon];
        [mode setOrder:(int)builder.order];
    }
    else if (![_values containsObject:mode])
    {
        mode = [builder customReg];
        [_values addObject:mode];
        [OAApplicationMode initRegVisibility];
    }
    
    [self reorderAppModes];
    [self saveCustomAppModesToSettings];
    return mode;
}

+ (BOOL) isProfileNameAvailable:(NSString *)profileName
{
    for (OAApplicationMode *profile in _values)
        if ([profile.toHumanString isEqual:profileName])
            return NO;
    return YES;
}

+ (void) deleteCustomModes:(NSArray<OAApplicationMode *> *) modes
{
    [_values removeObjectsInArray:modes];
    
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if ([modes containsObject:settings.applicationMode.get])
        [settings setApplicationModePref:_DEFAULT];
    [_cachedFilteredValues removeObjectsInArray:modes];
    [self saveCustomAppModesToSettings];
    
    for (OAApplicationMode *mode in modes) {
        if (mode.isCustomProfile)
        {
            NSString *backupDir = [[OsmAndApp instance].documentsPath stringByAppendingPathComponent:@"backup"];
            NSString *backupItemFilePath = [[backupDir stringByAppendingPathComponent:mode.stringKey] stringByAppendingPathExtension:@"osf"];
            [NSFileManager.defaultManager removeItemAtPath:backupItemFilePath error:nil];
        }
    }

    [[[OsmAndApp instance] availableAppModesChangedObservable] notifyEvent];
}

+ (void) changeProfileAvailability:(OAApplicationMode *) mode isSelected:(BOOL) isSelected
{
    NSMutableSet<OAApplicationMode *> *selectedModes = [NSMutableSet setWithArray:self.values];
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"%@,", _DEFAULT.stringKey];
    if ([OAApplicationMode.allPossibleValues containsObject:mode])
    {
        OAAppSettings *settings = OAAppSettings.sharedManager;
        if (isSelected)
        {
            [selectedModes addObject:mode];
        }
        else
        {
            [selectedModes removeObject:mode];
            if (settings.applicationMode.get == mode)
            {
                [settings setApplicationModePref:_DEFAULT];
            }
        }
        for (OAApplicationMode *m in selectedModes)
        {
            [str appendString:m.stringKey];
            [str appendString:@","];
        }
        [settings.availableApplicationModes set:str];
        [[[OsmAndApp instance] availableAppModesChangedObservable] notifyEvent];
    }
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
    {
        // add derived modes
        if ([set containsObject:m.parent])
            [set addObject:m];
    }
        
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

+ (OAApplicationModeBuilder *) createBase:(NSString *) stringKey
{
    OAApplicationModeBuilder *builder = [[OAApplicationModeBuilder alloc] init];
    builder.am = [[OAApplicationMode alloc] initWithName:@"" stringKey:stringKey];
    return builder;
}

+ (OAApplicationModeBuilder *) createCustomMode:(OAApplicationMode *) parent stringKey:(NSString *) stringKey
{
    OAApplicationModeBuilder *builder = [[OAApplicationModeBuilder alloc] init];
    builder.am = [[OAApplicationMode alloc] initWithName:@"" stringKey:stringKey];
    builder.am.parent = parent;
    return builder;
}

@end

@implementation OAApplicationModeBean

- (instancetype) init
{
    self = [super init];
    if (self) {
        _iconName = @"map_world_globe_dark";
        _iconColor = profile_icon_color_blue_light_default;
        _routeService = 0;
        _order = -1;
    }
    return self;
}

+ (OAApplicationModeBean *) fromJson:(NSDictionary *)jsonData
{
    OAApplicationModeBean *res = [[OAApplicationModeBean alloc] init];
    res.userProfileName = jsonData[@"userProfileName"];
    res.iconColor = [self parseColor:jsonData[@"iconColor"]];
    res.iconName = jsonData[@"iconName"];
    res.locIcon = [self parseLocationIcon:jsonData[@"locIcon"]];
    res.navIcon = [self parseNavIcon:jsonData[@"navIcon"]];
    res.order = [jsonData[@"order"] intValue];
    NSInteger routerService = [self.class parseRouterService:jsonData[@"routeService"]];
    res.routeService =  routerService;
    res.routingProfile = jsonData[@"routingProfile"];
    res.parent = jsonData[@"parent"];
    res.stringKey = jsonData[@"stringKey"];
    return res;
}

+ (EOANavigationIcon) parseNavIcon:(NSString *)locIcon
{
    if ([locIcon isEqualToString:@"DEFAULT"])
        return NAVIGATION_ICON_DEFAULT;
    else if ([locIcon isEqualToString:@"NAUTICAL"])
        return NAVIGATION_ICON_NAUTICAL;
    else if ([locIcon isEqualToString:@"CAR"])
        return NAVIGATION_ICON_CAR;
    return NAVIGATION_ICON_DEFAULT;
}

+ (EOALocationIcon) parseLocationIcon:(NSString *)locIcon
{
    if ([locIcon isEqualToString:@"DEFAULT"])
        return LOCATION_ICON_DEFAULT;
    else if ([locIcon isEqualToString:@"CAR"])
        return LOCATION_ICON_CAR;
    else if ([locIcon isEqualToString:@"BICYCLE"])
        return LOCATION_ICON_BICYCLE;
    return LOCATION_ICON_DEFAULT;
}

+ (NSInteger) parseRouterService:(NSString *)routerService
{
    // Brouter not currently supported
    if ([routerService isEqualToString:@"OSMAND"])
        return 0;
    else if ([routerService isEqualToString:@"DIRECT_TO"])
        return 1;
    else if ([routerService isEqualToString:@"STRAIGHT"])
        return 2;
    return 0; // OSMAND
}

+ (int) parseColor:(NSString *)color
{
    if ([color isEqualToString:@"DEFAULT"])
        return profile_icon_color_blue_light_default;
    else if ([color isEqualToString:@"PURPLE"])
        return profile_icon_color_purple_light;
    else if ([color isEqualToString:@"GREEN"])
        return profile_icon_color_green_light;
    else if ([color isEqualToString:@"BLUE"])
        return profile_icon_color_blue_light;
    else if ([color isEqualToString:@"RED"])
        return profile_icon_color_red_light;
    else if ([color isEqualToString:@"DARK_YELLOW"])
        return profile_icon_color_yellow_light;
    else if ([color isEqualToString:@"MAGENTA"])
        return profile_icon_color_magenta_light;
    return profile_icon_color_blue_light_default;
}

@end

@implementation OAApplicationModeBuilder

- (OAApplicationMode *) customReg
{
    OAApplicationMode *parent = _am.parent;
    
    [_am setParent:parent];
    [_am setUserProfileName:_userProfileName];
    [_am setIconName:_iconResName];
    [_am setRoutingProfile:_routingProfile];
    [_am setRouterService:_routeService];
    [_am setIconColor:(int)_iconColor];
    [_am setLocationIcon:_locationIcon];
    [_am setNavigationIcon:_navigationIcon];
    [_am setOrder:_order ? (int)_order : (int)OAApplicationMode.values.count];
    
    return _am;
}

@end
