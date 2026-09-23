//
//  OARoutingDataObject.m
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARoutingDataObject.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

static NSArray<NSString *> *_rpValues;

@implementation OARoutingDataObject

+ (void)initialize
{
    NSMutableArray<NSString *> *rpValues = [NSMutableArray array];
    for (NSInteger i = EOARoutingProfilesResourceDirectTo; i < EOARoutingProfilesResourceMoped + 1; i++)
    {
        [rpValues addObject:[self getProfileKey:i]];
    }
    _rpValues = rpValues;
}

- (instancetype)initWithStringKey:(NSString *)stringKey
                             name:(NSString *)name
                            descr:(NSString *)descr
                         iconName:(NSString *)iconName
                       isSelected:(BOOL)isSelected
                         fileName:(NSString *)fileName
                   derivedProfile:(NSString *)derivedProfile
{
    self = [super initWithStringKey:stringKey name:name descr:descr iconName:iconName isSelected:isSelected];
    if (self)
    {
        _fileName = fileName;
        _derivedProfile = derivedProfile;
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
        case EOARoutingProfilesResourceTrain:
            return @"TRAIN";
        case EOARoutingProfilesResourceBoat:
            return @"BOAT";
        case EOARoutingProfilesResourceHorsebackriding:
            return @"HORSEBACKRIDING";
        case EOARoutingProfilesResourceGeocoding:
            return @"GEOCODING";
        case EOARoutingProfilesResourceMoped:
            return @"MOPED";
        default:
            return @"";
    };
}

+ (NSString *) getIconName:(EOARoutingProfilesResource)res
{
    switch (res) {
        case EOARoutingProfilesResourceDirectTo:
            return ACImageNameIcCustomNavigationTypeDirectTo;
        case EOARoutingProfilesResourceStraightLine:
            return ACImageNameIcCustomStraightLine;
        case EOARoutingProfilesResourceBrouter:
            return ACImageNameIcCustomStraightLine;
        case EOARoutingProfilesResourceCar:
            return ACImageNameIcProfileCar;
        case EOARoutingProfilesResourcePedestrian:
            return ACImageNameIcProfilePedestrian;
        case EOARoutingProfilesResourceBicycle:
            return ACImageNameIcProfileBicycle;
        case EOARoutingProfilesResourceSki:
            return ACImageNameIcActionSkiing;
        case EOARoutingProfilesResourcePublicTransport:
            return ACImageNameIcActionBusDark;
        case EOARoutingProfilesResourceTrain:
            return ACImageNameIcActionTrain;
        case EOARoutingProfilesResourceBoat:
            return ACImageNameIcActionSailBoatDark;
        case EOARoutingProfilesResourceHorsebackriding:
            return ACImageNameIcActionHorse;
        case EOARoutingProfilesResourceGeocoding:
            return ACImageNameIcCustomOnline;
        case EOARoutingProfilesResourceMoped:
            return ACImageNameIcActionMotorScooter;
        default:
            return @"";
    };
}

+ (NSString *) getLocalizedName:(EOARoutingProfilesResource)res
{
    switch (res) {
        case EOARoutingProfilesResourceDirectTo:
            return OALocalizedString(@"routing_profile_direct_to");
        case EOARoutingProfilesResourceStraightLine:
            return OALocalizedString(@"routing_profile_straightline");
        case EOARoutingProfilesResourceBrouter:
            return OALocalizedString(@"nav_type_brouter");
        case EOARoutingProfilesResourceCar:
            return OALocalizedString(@"routing_engine_vehicle_type_driving");
        case EOARoutingProfilesResourcePedestrian:
            return OALocalizedString(@"rendering_value_pedestrian_name");
        case EOARoutingProfilesResourceBicycle:
            return OALocalizedString(@"app_mode_bicycle");
        case EOARoutingProfilesResourceSki:
            return OALocalizedString(@"routing_profile_ski");
        case EOARoutingProfilesResourcePublicTransport:
            return OALocalizedString(@"poi_filter_public_transport");
        case EOARoutingProfilesResourceTrain:
            return OALocalizedString(@"app_mode_train");
        case EOARoutingProfilesResourceBoat:
            return OALocalizedString(@"app_mode_boat");
        case EOARoutingProfilesResourceHorsebackriding:
            return OALocalizedString(@"horseback_riding");
        case EOARoutingProfilesResourceGeocoding:
            return OALocalizedString(@"routing_profile_geocoding");
        case EOARoutingProfilesResourceMoped:
            return OALocalizedString(@"app_mode_moped");
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
    else if ([key isEqualToString: @"TRAIN"])
        return EOARoutingProfilesResourceTrain;
    else if ([key isEqualToString: @"BOAT"])
        return EOARoutingProfilesResourceBoat;
    else if ([key isEqualToString: @"HORSEBACKRIDING"])
        return EOARoutingProfilesResourceHorsebackriding;
    else if ([key isEqualToString: @"GEOCODING"])
        return EOARoutingProfilesResourceGeocoding;
    else if ([key isEqualToString: @"MOPED"])
        return EOARoutingProfilesResourceMoped;
    else
        return EOARoutingProfilesResourceUndefined;
}

+ (BOOL)isRpValue:(NSString *)value
{
    return [_rpValues containsObject:value];
}

@end

