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
#import "OALocationIcon.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"

#define kBackgroundDistanceSlow 5
#define kBackgroundDistanceFast 10

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

static NSMutableArray<OAApplicationMode *> *_defaultValues;
static NSMutableArray<OAApplicationMode *> *_values;
static NSMutableArray<OAApplicationMode *> *_cachedFilteredValues;
static NSString *_cachedAvailableApplicationModes;
static OAAutoObserverProxy* _listener;


static OAApplicationMode *_DEFAULT;
static OAApplicationMode *_CAR;
static OAApplicationMode *_BICYCLE;
static OAApplicationMode *_PUBLIC_TRANSPORT;
static OAApplicationMode *_TRAIN;
static OAApplicationMode *_PEDESTRIAN;
static OAApplicationMode *_AIRCRAFT;
static OAApplicationMode *_TRUCK;
static OAApplicationMode *_MOTORCYCLE;
static OAApplicationMode *_MOPED;
static OAApplicationMode *_BOAT;
static OAApplicationMode *_SKI;
static OAApplicationMode *_HORSE;

static int PROFILE_NONE = 0;
static int PROFILE_TRUCK = 1000;

+ (void) initialize
{
    _widgetsVisibilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _widgetsAvailabilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _values = [NSMutableArray array];
    _defaultValues = [NSMutableArray array];
    _cachedFilteredValues = [NSMutableArray array];
    _cachedAvailableApplicationModes = @"";

    _DEFAULT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"rendering_value_browse_map_name") stringKey:@"default"];
    _DEFAULT.descr = OALocalizedString(@"profile_type_base_string");
    [_DEFAULT reg];
    
    _CAR = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"routing_engine_vehicle_type_driving") stringKey:@"car"];
    _CAR.descr = OALocalizedString(@"base_profile_descr_car");
    [_CAR reg];
    
    _BICYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_bicycle") stringKey:@"bicycle"];
    _BICYCLE.descr = OALocalizedString(@"base_profile_descr_bicycle");
    [_BICYCLE reg];
    
    _PEDESTRIAN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_pedestrian") stringKey:@"pedestrian"];
    _PEDESTRIAN.descr = OALocalizedString(@"base_profile_descr_pedestrian");
    [_PEDESTRIAN reg];
    
    _PUBLIC_TRANSPORT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"poi_filter_public_transport") stringKey:@"public_transport"];
    _PUBLIC_TRANSPORT.descr = OALocalizedString(@"base_profile_descr_public_transport");
    [_PUBLIC_TRANSPORT reg];
    
    _TRAIN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_train") stringKey:@"train"];
    _TRAIN.descr = OALocalizedString(@"app_mode_train");
    [_TRAIN reg];
    
    _AIRCRAFT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_aircraft") stringKey:@"aircraft"];
    _AIRCRAFT.descr = OALocalizedString(@"base_profile_descr_aircraft");
    [_AIRCRAFT reg];
    
    _TRUCK = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_truck") stringKey:@"truck"];
    _TRUCK.descr = OALocalizedString(@"app_mode_truck");
    [_TRUCK reg];
    
    _MOTORCYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_motorcycle") stringKey:@"motorcycle"];
    _MOTORCYCLE.descr = OALocalizedString(@"app_mode_motorcycle");
    [_MOTORCYCLE reg];
    
    _MOPED = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_moped") stringKey:@"moped"];
    _MOPED.descr = OALocalizedString(@"app_mode_bicycle");
    [_MOPED reg];

    _BOAT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_boat") stringKey:@"boat"];
    _BOAT.descr = OALocalizedString(@"base_profile_descr_boat");
    [_BOAT reg];
    
    _SKI = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_skiing") stringKey:@"ski"];
    _SKI.descr = OALocalizedString(@"app_mode_skiing");
    [_SKI reg];
    
    _HORSE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"horseback_riding") stringKey:@"horse"];
    _HORSE.descr = OALocalizedString(@"horseback_riding");
    [_HORSE reg];
}

- (void) reg
{
    [_values addObject:self];
    [_defaultValues addObject:self];
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

+ (OAApplicationMode *) TRUCK;
{
    return _TRUCK;
}

+ (OAApplicationMode *) MOTORCYCLE;
{
    return _MOTORCYCLE;
}

+ (OAApplicationMode *) MOPED;
{
    return _MOPED;
}

+ (OAApplicationMode *) BOAT;
{
    return _BOAT;
}

+ (OAApplicationMode *) PUBLIC_TRANSPORT
{
    return _PUBLIC_TRANSPORT;
}

+ (OAApplicationMode *) TRAIN;
{
    return _TRAIN;
}

+ (OAApplicationMode *) SKI
{
    return _SKI;
}

+ (OAApplicationMode *) HORSE
{
    return _HORSE;
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
    [builder setCustomIconColor:modeBean.customIconColor];
    [builder setRoutingProfile:modeBean.routingProfile];
    [builder setDerivedProfile:modeBean.derivedProfile];
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
    NSString *available = OAAppSettings.sharedManager.availableApplicationModes.get;
    if (_cachedFilteredValues.count == 0 || ![_cachedAvailableApplicationModes isEqualToString:available])
    {
        if (!_listener)
        {
            _listener = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onAvailableAppModesChanged)
                                                   andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
        }
        _cachedFilteredValues = [NSMutableArray array];
        _cachedAvailableApplicationModes = available;
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

+ (OAApplicationMode *) getFirstAvailableNavigationMode
{
    for (OAApplicationMode *mode in self.values)
    {
        if (mode != self.DEFAULT)
            return mode;
    }
    return self.CAR;
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
        @"customIconColor" : @([self getColorToExport]),
        @"iconName" : self.getIconName,
        @"parent" : self.parent ? self.parent.stringKey : @"",
        @"routeService" : self.getRouterServiceName,
        @"derivedProfile" : self.getDerivedProfile,
        @"routingProfile" : self.getRoutingProfile,
        @"locIcon" : [self.getLocationIcon name],
        @"navIcon" : [self.getNavigationIcon name],
        @"order" : @(self.getOrder)
    };
}

- (int) getColorToExport
{
    int customColor = [self getCustomIconColor];
    if (customColor == -1)
    {
        UIColor *color = UIColorFromRGB([self getIconColor]);
        return [color toARGBNumber];
    }
    return customColor;
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
    for (OAApplicationMode *mode in _defaultValues)
    {
        if ([mode.stringKey isEqualToString:self.stringKey])
            return NO;
    }
    return YES;
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

- (NSString *) getDerivedProfile
{
    return [OAAppSettings.sharedManager.derivedProfile get:self];
}

- (void) setDerivedProfile:(NSString *)derivedProfile
{
    if (derivedProfile.length > 0)
        [OAAppSettings.sharedManager.derivedProfile set:derivedProfile mode:self];
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

- (OALocationIcon *) getNavigationIcon
{
    NSString *savedName = [OAAppSettings.sharedManager.navigationIcon get:self];
    OALocationIcon *icon = [OALocationIcon locationIconWithName:savedName];
    return icon ? icon : [OALocationIcon MOVEMENT_DEFAULT];
}

- (void) setNavigationIconName:(NSString *) navIcon
{
    [OAAppSettings.sharedManager.navigationIcon set:navIcon mode:self];
}

- (OALocationIcon *) getLocationIcon
{
    NSString *savedName = [OAAppSettings.sharedManager.locationIcon get:self];
    OALocationIcon *icon = [OALocationIcon locationIconWithName:savedName];
    return icon ? icon : [OALocationIcon DEFAULT];
}

- (void) setLocationIconName:(NSString *) locIcon
{
    [OAAppSettings.sharedManager.locationIcon set:locIcon mode:self];
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

- (int) getCustomIconColor
{
    return [OAAppSettings.sharedManager.profileCustomIconColor get:self];
}

- (void) setCustomIconColor:(int)iconColor
{
    [OAAppSettings.sharedManager.profileCustomIconColor set:iconColor mode:self];
}

- (UIColor *) getProfileColor
{
    int customProfileColor = [self getCustomIconColor];
    if (customProfileColor != -1)
        return UIColorFromARGB(customProfileColor);
    return UIColorFromRGB([self getIconColor]);
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

- (NSInteger) getBackgroundDistanceFilter
{
    return [self hasFastSpeed] ? kBackgroundDistanceFast : kBackgroundDistanceSlow;
}

- (OAApplicationModeBean *) toModeBean
{
    return [OAApplicationModeBean fromJson:self.toJson];
}

+ (void) onApplicationStart
{
    [self initModesParents];
    [self initCustomModes];
    [self initModesParams];
    [OAWidgetsAvailabilityHelper initRegVisibility];
    [self reorderAppModes];
}

+ (void) initModesParents
{
    // We can't set parent profiles directly in initialize() method. Because it creates infinity loop on app initialisation:
    // OAAppSetttings.init() -> OAApplicationMode.init() -> OAAppSetttings.init() -> OAApplicationMode...
    [_TRUCK setParent:_CAR];
    [_MOTORCYCLE setParent:_CAR];
    [_MOPED setParent:_BICYCLE];
}

+ (void) initModesParams
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if ([settings.appModeOrder isSetForMode:_PUBLIC_TRANSPORT] && ![settings.appModeOrder isSetForMode:_TRAIN])
        [_TRAIN setOrder:_PUBLIC_TRANSPORT.getOrder + 1];
    if ([settings.appModeOrder isSetForMode:_PEDESTRIAN])
    {
        if (![settings.appModeOrder isSetForMode:_TRUCK])
            [_TRUCK setOrder:_PEDESTRIAN.getOrder + 1];
        if (![settings.appModeOrder isSetForMode:_MOTORCYCLE])
            [_MOTORCYCLE setOrder:_PEDESTRIAN.getOrder + 1];
        if (![settings.appModeOrder isSetForMode:_MOPED])
            [_MOPED setOrder:_MOTORCYCLE.getOrder + 1];
    }
    if ([settings.appModeOrder isSetForMode:_SKI] && ![settings.appModeOrder isSetForMode:_HORSE])
        [_HORSE setOrder:_SKI.getOrder + 1];
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
    [_defaultValues sortUsingComparator:^NSComparisonResult(OAApplicationMode *obj1, OAApplicationMode *obj2) {
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
        [mode setDerivedProfile:builder.derivedProfile];
        [mode setRouterService:builder.routeService];
        [mode setIconColor:(int)builder.iconColor];
        [mode setCustomIconColor:(int)builder.customIconColor];
        [mode setLocationIconName:builder.locationIcon];
        [mode setNavigationIconName:builder.navigationIcon];
        [mode setOrder:(int)builder.order];
    }
    else if (![_values containsObject:mode])
    {
        mode = [builder customReg];
        [_values addObject:mode];
        [OAWidgetsAvailabilityHelper initRegVisibility];
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
                if ([_values containsObject:_DEFAULT])
                    [settings setApplicationModePref:_DEFAULT];
                else
                    [settings setApplicationModePref:[_values firstObject]];
            }
            if (settings.defaultApplicationMode.get == mode)
                [settings.defaultApplicationMode set:settings.applicationMode.get];
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
    {
        if ([p.stringKey isEqualToString:key])
            return p;
    }

    return def;
}

- (int) getRouteTypeProfile
{
	if ([self isDerivedRoutingFrom:OAApplicationMode.TRUCK]){
		return PROFILE_TRUCK;
	}
	return PROFILE_NONE;
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
    res.customIconColor = [self parseCustomColor:jsonData[@"customIconColor"]];
    res.iconName = [self parseProfileIcon:jsonData[@"iconName"]];
    res.locIcon = [[OALocationIcon locationIconWithName:jsonData[@"locIcon"]] name];
    res.navIcon = [[OALocationIcon locationIconWithName:jsonData[@"navIcon"]] name];
    res.order = [jsonData[@"order"] intValue];
    NSInteger routerService = [self.class parseRouterService:jsonData[@"routeService"]];
    res.routeService = routerService;
    res.derivedProfile = jsonData[@"derivedProfile"];
    res.routingProfile = jsonData[@"routingProfile"];
    res.parent = jsonData[@"parent"];
    res.stringKey = jsonData[@"stringKey"];
    return res;
}

+ (NSString *)parseProfileIcon:(NSString *)iconName
{
    if ([iconName isEqualToString:@"ic_action_truck_dark"])
        return @"ic_action_truck";
    return iconName;
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

+ (int) parseCustomColor:(id)value
{
    if (value)
    {
        if ([value isKindOfClass:NSString.class])
            return [[UIColor colorFromString:((NSString *)value)] toARGBNumber];
        else if ([value isKindOfClass:NSNumber.class])
            return ((NSNumber *) value).intValue;
    }
    return -1;
}

- (UIColor *) getProfileColor
{
    if (_customIconColor != -1)
        return UIColorFromARGB(_customIconColor);
    return UIColorFromRGB(_iconColor);
}

@end

@implementation OAApplicationModeBuilder

- (OAApplicationMode *) customReg
{
    OAApplicationMode *parent = _am.parent;
    
    [_am setParent:parent];
    [_am setUserProfileName:_userProfileName];
    [_am setIconName:_iconResName];
    [_am setDerivedProfile:_derivedProfile];
    [_am setRoutingProfile:_routingProfile];
    [_am setRouterService:_routeService];
    [_am setIconColor:(int)_iconColor];
    [_am setCustomIconColor:(int)_customIconColor];
    [_am setLocationIconName:_locationIcon];
    [_am setNavigationIconName:_navigationIcon];
    [_am setOrder:_order ? (int)_order : (int)OAApplicationMode.values.count];
    
    return _am;
}

@end
