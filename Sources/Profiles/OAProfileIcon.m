//
//  OAProfileIcon.m
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileIcon.h"
#import "Localization.h"

@interface OAProfileIcon()

@property (nonatomic) EOAProfileIcon profileIcon;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *iconName;

@end

@implementation OAProfileIcon

+ (instancetype) withProfileIcon:(EOAProfileIcon)profileIcon
{
    OAProfileIcon *obj = [[OAProfileIcon alloc] init];
    if (obj)
    {
        obj.profileIcon = profileIcon;
        obj.name = [self.class getName:profileIcon];
        obj.iconName = [self.class getIconName:profileIcon];
    }

    return obj;
}

+ (NSArray<OAProfileIcon *> *) values;
{
    return @[ [OAProfileIcon withProfileIcon:PROFILE_ICON_DEFAULT],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_CAR],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_TAXI],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_TRUCK],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_SHUTTLE_BUS],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_BUS],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_SUBWAY],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_MOTORCYCLE],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_BICYCLE],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_HORSE],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_PEDESTRIAN],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_TREKKING],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_SKIING],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_SAIL_BOAT],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_AIRCRAFT],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_HELICOPTER],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_TRANSPORTER],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_MONOWHEEL],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_SCOOTER],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_UFO],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_OFFROAD],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_CAMPERVAN],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_CAMPER],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_PICKUP_TRUCK],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_WAGON],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_UTV],
              [OAProfileIcon withProfileIcon:PROFILE_ICON_OSM] ];
}

+ (NSString *) getName:(EOAProfileIcon)profileIcon
{
    switch (profileIcon)
    {
        case PROFILE_ICON_DEFAULT:
            return OALocalizedString(@"app_mode_default");
        case PROFILE_ICON_CAR:
            return OALocalizedString(@"app_mode_car");
        case PROFILE_ICON_TAXI:
            return OALocalizedString(@"app_mode_taxi");
        case PROFILE_ICON_TRUCK:
            return OALocalizedString(@"app_mode_truck");
        case PROFILE_ICON_SHUTTLE_BUS:
            return OALocalizedString(@"app_mode_shuttle_bus");
        case PROFILE_ICON_BUS:
            return OALocalizedString(@"app_mode_bus");
        case PROFILE_ICON_SUBWAY:
            return OALocalizedString(@"app_mode_subway");
        case PROFILE_ICON_MOTORCYCLE:
            return OALocalizedString(@"app_mode_motorcycle");
        case PROFILE_ICON_BICYCLE:
            return OALocalizedString(@"app_mode_bicycle");
        case PROFILE_ICON_HORSE:
            return OALocalizedString(@"app_mode_horse");
        case PROFILE_ICON_PEDESTRIAN:
            return OALocalizedString(@"app_mode_pedestrian");
        case PROFILE_ICON_TREKKING:
            return OALocalizedString(@"app_mode_hiking");
        case PROFILE_ICON_SKIING:
            return OALocalizedString(@"app_mode_skiing");
        case PROFILE_ICON_SAIL_BOAT:
            return OALocalizedString(@"app_mode_boat");
        case PROFILE_ICON_AIRCRAFT:
            return OALocalizedString(@"app_mode_aircraft");
        case PROFILE_ICON_HELICOPTER:
            return OALocalizedString(@"app_mode_helicopter");
        case PROFILE_ICON_TRANSPORTER:
            return OALocalizedString(@"app_mode_personal_transporter");
        case PROFILE_ICON_MONOWHEEL:
            return OALocalizedString(@"app_mode_monowheel");
        case PROFILE_ICON_SCOOTER:
            return OALocalizedString(@"app_mode_scooter");
        case PROFILE_ICON_UFO:
            return OALocalizedString(@"app_mode_ufo");
        case PROFILE_ICON_OFFROAD:
            return OALocalizedString(@"app_mode_offroad");
        case PROFILE_ICON_CAMPERVAN:
            return OALocalizedString(@"app_mode_campervan");
        case PROFILE_ICON_CAMPER:
            return OALocalizedString(@"app_mode_camper");
        case PROFILE_ICON_PICKUP_TRUCK:
            return OALocalizedString(@"app_mode_pickup_truck");
        case PROFILE_ICON_WAGON:
            return OALocalizedString(@"app_mode_wagon");
        case PROFILE_ICON_UTV:
            return OALocalizedString(@"app_mode_utv");
        case PROFILE_ICON_OSM:
            return OALocalizedString(@"app_mode_osm");
        default:
            return @"";
    }
}

+ (NSString *) getIconName:(EOAProfileIcon)profileIcon
{
    switch (profileIcon)
    {
        case PROFILE_ICON_DEFAULT:
            return @"ic_world_globe_dark";
        case PROFILE_ICON_CAR:
            return @"ic_action_car_dark";
        case PROFILE_ICON_TAXI:
            return @"ic_action_taxi";
        case PROFILE_ICON_TRUCK:
            return @"ic_action_truck";
        case PROFILE_ICON_SHUTTLE_BUS:
            return @"ic_action_shuttle_bus";
        case PROFILE_ICON_BUS:
            return @"ic_action_bus_dark";
        case PROFILE_ICON_SUBWAY:
            return @"ic_action_subway";
        case PROFILE_ICON_MOTORCYCLE:
            return @"ic_action_motorcycle_dark";
        case PROFILE_ICON_BICYCLE:
            return @"ic_action_bicycle_dark";
        case PROFILE_ICON_HORSE:
            return @"ic_action_horse";
        case PROFILE_ICON_PEDESTRIAN:
            return @"ic_action_pedestrian_dark";
        case PROFILE_ICON_TREKKING:
            return @"ic_action_trekking_dark";
        case PROFILE_ICON_SKIING:
            return @"ic_action_skiing";
        case PROFILE_ICON_SAIL_BOAT:
            return @"ic_action_sail_boat_dark";
        case PROFILE_ICON_AIRCRAFT:
            return @"ic_action_aircraft";
        case PROFILE_ICON_HELICOPTER:
            return @"ic_action_helicopter";
        case PROFILE_ICON_TRANSPORTER:
            return @"ic_action_personal_transporter";
        case PROFILE_ICON_MONOWHEEL:
            return @"ic_action_monowheel";
        case PROFILE_ICON_SCOOTER:
            return @"ic_action_scooter";
        case PROFILE_ICON_UFO:
            return @"ic_action_ufo";
        case PROFILE_ICON_OFFROAD:
            return @"ic_action_offroad";
        case PROFILE_ICON_CAMPERVAN:
            return @"ic_action_campervan";
        case PROFILE_ICON_CAMPER:
            return @"ic_action_camper";
        case PROFILE_ICON_PICKUP_TRUCK:
            return @"ic_action_pickup_truck";
        case PROFILE_ICON_WAGON:
            return @"ic_action_wagon";
        case PROFILE_ICON_UTV:
            return @"ic_action_utv";
        case PROFILE_ICON_OSM:
            return @"ic_action_openstreetmap_logo";
        default:
            return @"";
    }
}

@end
