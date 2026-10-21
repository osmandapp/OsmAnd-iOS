//
//  OAProfileIcon.m
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileIcon.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

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
            return ACImageNameIcWorldGlobeDark;
        case PROFILE_ICON_CAR:
            return ACImageNameIcActionCarDark;
        case PROFILE_ICON_TAXI:
            return ACImageNameIcActionTaxi;
        case PROFILE_ICON_TRUCK:
            return ACImageNameIcActionTruckDark;
        case PROFILE_ICON_SHUTTLE_BUS:
            return ACImageNameIcActionShuttleBus;
        case PROFILE_ICON_BUS:
            return ACImageNameIcActionBusDark;
        case PROFILE_ICON_SUBWAY:
            return ACImageNameIcActionSubway;
        case PROFILE_ICON_MOTORCYCLE:
            return ACImageNameIcActionMotorcycleDark;
        case PROFILE_ICON_BICYCLE:
            return ACImageNameIcActionBicycleDark;
        case PROFILE_ICON_HORSE:
            return ACImageNameIcActionHorse;
        case PROFILE_ICON_PEDESTRIAN:
            return ACImageNameIcActionPedestrianDark;
        case PROFILE_ICON_TREKKING:
            return ACImageNameIcActionTrekkingDark;
        case PROFILE_ICON_SKIING:
            return ACImageNameIcActionSkiing;
        case PROFILE_ICON_SAIL_BOAT:
            return ACImageNameIcActionSailBoatDark;
        case PROFILE_ICON_AIRCRAFT:
            return ACImageNameIcActionAircraft;
        case PROFILE_ICON_HELICOPTER:
            return ACImageNameIcActionHelicopter;
        case PROFILE_ICON_TRANSPORTER:
            return ACImageNameIcActionPersonalTransporter;
        case PROFILE_ICON_MONOWHEEL:
            return ACImageNameIcActionMonowheel;
        case PROFILE_ICON_SCOOTER:
            return ACImageNameIcActionScooter;
        case PROFILE_ICON_UFO:
            return ACImageNameIcActionUfo;
        case PROFILE_ICON_OFFROAD:
            return ACImageNameIcActionOffroad;
        case PROFILE_ICON_CAMPERVAN:
            return ACImageNameIcActionCampervan;
        case PROFILE_ICON_CAMPER:
            return ACImageNameIcActionCamper;
        case PROFILE_ICON_PICKUP_TRUCK:
            return ACImageNameIcActionPickupTruck;
        case PROFILE_ICON_WAGON:
            return ACImageNameIcActionWagon;
        case PROFILE_ICON_UTV:
            return ACImageNameIcActionUtv;
        case PROFILE_ICON_OSM:
            return ACImageNameIcActionOpenstreetmapLogo;
        default:
            return @"";
    }
}

@end
