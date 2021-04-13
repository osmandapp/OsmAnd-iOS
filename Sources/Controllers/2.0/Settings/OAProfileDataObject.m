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

- (NSComparisonResult)compare:(OAProfileDataObject *)other
{
    return [_name compare:other.name];
}

@end

@implementation OARoutingProfileDataObject

+ (void)initialize
{
    NSMutableDictionary<NSString *, OARoutingProfileDataObject *> *rps = [NSMutableDictionary new];
    for (NSInteger i = EOARoutingProfilesResourceDirectTo; i < EOARoutingProfilesResourceGeocoding; i++)
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

- (instancetype) initWithResource:(EOARoutingProfilesResource)res
{
    self = [super init];
    if (self) {
        self.stringKey = [OARoutingProfileDataObject getProfileKey:res];
        self.name = [OARoutingProfileDataObject getLocalizedName:res];
        self.iconName = [OARoutingProfileDataObject getIconName:res];
    }
    return self;
}

+ (NSString *) getProfileKey:(EOARoutingProfilesResource)type
{
    switch (type) {
        case EOARoutingProfilesResourceDirectTo:
            return @"DIRECT_TO_MODE";
        case EOARoutingProfilesResourceStraightLine:
            return @"STRAIGHT_LINE_MODE";
        case EOARoutingProfilesResourceBrouter:
            return @"BROUTER_MODE";
        case EOARoutingProfilesResourceCar:
            return @"CAR";
        case EOARoutingProfilesResourcePedestrian:
            return @"PEDESTRIAN";
        case EOARoutingProfilesResourceBicycle:
            return @"BICYCLE";
        case EOARoutingProfilesResourceSki:
            return @"SKI";
        case EOARoutingProfilesResourcePublicTransport:
            return @"PUBLIC_TRANSPORT";
        case EOARoutingProfilesResourceBoat:
            return @"BOAT";
        case EOARoutingProfilesResourceGeocoding:
            return @"GEOCODING";
        default:
            return @"";
    };
}

+ (NSString *) getIconName:(EOARoutingProfilesResource)res
{
    switch (res) {
        case EOARoutingProfilesResourceDirectTo:
            return @"ic_custom_navigation_type_direct_to";
        case EOARoutingProfilesResourceStraightLine:
            return @"ic_custom_straight_line";
        case EOARoutingProfilesResourceBrouter:
            return @"ic_custom_straight_line";
        case EOARoutingProfilesResourceCar:
            return @"ic_profile_car";
        case EOARoutingProfilesResourcePedestrian:
            return @"ic_profile_pedestrian";
        case EOARoutingProfilesResourceBicycle:
            return @"ic_profile_bicycle";
        case EOARoutingProfilesResourceSki:
            return @"ic_action_skiing";
        case EOARoutingProfilesResourcePublicTransport:
            return @"ic_action_bus_dark";
        case EOARoutingProfilesResourceBoat:
            return @"ic_action_sail_boat_dark";
        case EOARoutingProfilesResourceGeocoding:
            return @"ic_custom_online";
        default:
            return @"";
    };
}

+ (NSString *) getLocalizedName:(EOARoutingProfilesResource)res
{
    switch (res) {
        case EOARoutingProfilesResourceDirectTo:
            return OALocalizedString(@"nav_type_direct_to");
        case EOARoutingProfilesResourceStraightLine:
            return OALocalizedString(@"nav_type_straight_line");
        case EOARoutingProfilesResourceBrouter:
            return OALocalizedString(@"nav_type_brouter");
        case EOARoutingProfilesResourceCar:
            return OALocalizedString(@"m_style_car");
        case EOARoutingProfilesResourcePedestrian:
            return OALocalizedString(@"rendering_value_pedestrian_name");
        case EOARoutingProfilesResourceBicycle:
            return OALocalizedString(@"m_style_bicycle");
        case EOARoutingProfilesResourceSki:
            return OALocalizedString(@"nav_type_ski");
        case EOARoutingProfilesResourcePublicTransport:
            return OALocalizedString(@"m_style_pulic_transport");
        case EOARoutingProfilesResourceBoat:
            return OALocalizedString(@"app_mode_boat");
        case EOARoutingProfilesResourceGeocoding:
            return OALocalizedString(@"nav_type_geocoding");
        default:
            return @"";
    };
}

+ (EOARoutingProfilesResource) getValueOf:(NSString *)key
{
    if ([key isEqualToString: @"DIRECT_TO_MODE"])
        return EOARoutingProfilesResourceDirectTo;
    else if ([key isEqualToString: @"STRAIGHT_LINE_MODE"])
        return EOARoutingProfilesResourceStraightLine;
    else if ([key isEqualToString: @"BROUTER_MODE"])
        return EOARoutingProfilesResourceBrouter;
    else if ([key isEqualToString: @"CAR"])
        return EOARoutingProfilesResourceCar;
    else if ([key isEqualToString: @"PEDESTRIAN"])
        return EOARoutingProfilesResourcePedestrian;
    else if ([key isEqualToString: @"BICYCLE"])
        return EOARoutingProfilesResourceBicycle;
    else if ([key isEqualToString: @"SKI"])
        return EOARoutingProfilesResourceSki;
    else if ([key isEqualToString: @"PUBLIC_TRANSPORT"])
        return EOARoutingProfilesResourcePublicTransport;
    else if ([key isEqualToString: @"BOAT"])
        return EOARoutingProfilesResourceBoat;
    else if ([key isEqualToString: @"GEOCODING"])
        return EOARoutingProfilesResourceGeocoding;
    else
        return EOARoutingProfilesResourceUndefined;
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
