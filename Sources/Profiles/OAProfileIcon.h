//
//  OAProfileIcon.h
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAProfileIcon)
{
    PROFILE_ICON_DEFAULT = 0,
    PROFILE_ICON_CAR,
    PROFILE_ICON_TAXI,
    PROFILE_ICON_TRUCK,
    PROFILE_ICON_SHUTTLE_BUS,
    PROFILE_ICON_BUS,
    PROFILE_ICON_SUBWAY,
    PROFILE_ICON_MOTORCYCLE,
    PROFILE_ICON_BICYCLE,
    PROFILE_ICON_HORSE,
    PROFILE_ICON_PEDESTRIAN,
    PROFILE_ICON_TREKKING,
    PROFILE_ICON_SKIING,
    PROFILE_ICON_SAIL_BOAT,
    PROFILE_ICON_AIRCRAFT,
    PROFILE_ICON_HELICOPTER,
    PROFILE_ICON_TRANSPORTER,
    PROFILE_ICON_MONOWHEEL,
    PROFILE_ICON_SCOOTER,
    PROFILE_ICON_UFO,
    PROFILE_ICON_OFFROAD,
    PROFILE_ICON_CAMPERVAN,
    PROFILE_ICON_CAMPER,
    PROFILE_ICON_PICKUP_TRUCK,
    PROFILE_ICON_WAGON,
    PROFILE_ICON_UTV,
    PROFILE_ICON_OSM
};

@interface OAProfileIcon : NSObject

@property (nonatomic, readonly) EOAProfileIcon profileIconColor;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *iconName;

+ (instancetype) withProfileIcon:(EOAProfileIcon)profileIconColor;

+ (NSArray<OAProfileIcon *> *) values;

+ (NSString *) getName:(EOAProfileIcon)profileIcon;
+ (NSString *) getIconName:(EOAProfileIcon)profileIcon;

@end

NS_ASSUME_NONNULL_END
