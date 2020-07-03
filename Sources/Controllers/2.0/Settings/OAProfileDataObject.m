//
//  OAProfileDataObject.m
//  OsmAnd
//
//  Created by Paul on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileDataObject.h"
#import "Localization.h"

static NSDictionary<NSString *, OARoutingProfileDataObject *> *_rpValues;

@implementation OAProfileDataObject

- (instancetype)initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected
{
    self = [super init];
    if (self) {
        _stringKey = stringKey;
        _name = name;
        _descr = descr;
        _iconName = iconName;
        _isSelected = isSelected;
    }
    return self;
}

@end

@implementation OARoutingProfileDataObject

+ (void)initialize
{
    NSMutableDictionary<NSString *, OARoutingProfileDataObject *> *rps = [NSMutableDictionary new];
    for (NSInteger i = EOARouringProfilesResourceDirectTo; i < EOARouringProfilesResourceGeocoding; i++)
    {
        [rps setObject:[[OARoutingProfileDataObject alloc] initWithResource:i] forKey:[self getProfileKey:i]];
    }
    _rpValues = [NSDictionary dictionaryWithDictionary:rps];
}

- (instancetype)initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected fileName:(NSString *)fileName
{
    self = [super initWithStringKey:stringKey name:name descr:descr iconName:iconName isSelected:isSelected];
    if (self) {
        _fileName = fileName;
    }
    return self;
}

- (instancetype) initWithResource:(EOARouringProfilesResource)res
{
    self = [super init];
    if (self) {
        self.stringKey = [OARoutingProfileDataObject getProfileKey:res];
        self.name = [OARoutingProfileDataObject getLocalizedName:res];
        self.iconName = [OARoutingProfileDataObject getIconName:res];
    }
    return self;
}

+ (NSString *) getProfileKey:(EOARouringProfilesResource)type
{
    switch (type) {
        case EOARouringProfilesResourceDirectTo:
            return @"DIRECT_TO_MODE";
        case EOARouringProfilesResourceStraightLine:
            return @"STRAIGHT_LINE_MODE";
        case EOARouringProfilesResourceBrouter:
            return @"BROUTER_MODE";
        case EOARouringProfilesResourceCar:
            return @"CAR";
        case EOARouringProfilesResourcePedestrian:
            return @"PEDESTRIAN";
        case EOARouringProfilesResourceBicycle:
            return @"BICYCLE";
        case EOARouringProfilesResourceSki:
            return @"SKI";
        case EOARouringProfilesResourcePublicTransport:
            return @"PUBLIC_TRANSPORT";
        case EOARouringProfilesResourceBoat:
            return @"BOAT";
        case EOARouringProfilesResourceGeocoding:
            return @"GEOCODING";
        default:
            return @"";
    };
}

+ (NSString *) getIconName:(EOARouringProfilesResource)res
{
    switch (res) {
        case EOARouringProfilesResourceDirectTo:
            return @"ic_custom_navigation_type_direct_to";
        case EOARouringProfilesResourceStraightLine:
            return @"ic_custom_straight_line";
        case EOARouringProfilesResourceBrouter:
            return @"ic_custom_straight_line";
        case EOARouringProfilesResourceCar:
            return @"ic_profile_car";
        case EOARouringProfilesResourcePedestrian:
            return @"ic_profile_pedestrian";
        case EOARouringProfilesResourceBicycle:
            return @"ic_profile_bicycle";
        case EOARouringProfilesResourceSki:
            return @"ic_action_skiing";
        case EOARouringProfilesResourcePublicTransport:
            return @"ic_action_bus_dark";
        case EOARouringProfilesResourceBoat:
            return @"ic_action_sail_boat_dark";
        case EOARouringProfilesResourceGeocoding:
            return @"ic_custom_online";
        default:
            return @"";
    };
}

+ (NSString *) getLocalizedName:(EOARouringProfilesResource)res
{
    switch (res) {
        case EOARouringProfilesResourceDirectTo:
            return OALocalizedString(@"nav_type_direct_to");
        case EOARouringProfilesResourceStraightLine:
            return OALocalizedString(@"nav_type_straight_line");
        case EOARouringProfilesResourceBrouter:
            return OALocalizedString(@"nav_type_brouter");
        case EOARouringProfilesResourceCar:
            return OALocalizedString(@"m_style_car");
        case EOARouringProfilesResourcePedestrian:
            return OALocalizedString(@"rendering_value_pedestrian_name");
        case EOARouringProfilesResourceBicycle:
            return OALocalizedString(@"m_style_bicycle");
        case EOARouringProfilesResourceSki:
            return OALocalizedString(@"nav_type_ski");
        case EOARouringProfilesResourcePublicTransport:
            return OALocalizedString(@"m_style_pulic_transport");
        case EOARouringProfilesResourceBoat:
            return OALocalizedString(@"app_mode_boat");
        case EOARouringProfilesResourceGeocoding:
            return OALocalizedString(@"nav_type_geocoding");
        default:
            return @"";
    };
}

+ (OARoutingProfileDataObject *) getRoutingProfileDataByName:(NSString *)key
{
    return _rpValues[key];
}

+ (BOOL)isRpValue:(NSString *)value
{
    return [_rpValues objectForKey:value] != nil;
}

@end
