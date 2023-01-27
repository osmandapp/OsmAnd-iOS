//
//  OAProfileIconColor.m
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileIconColor.h"
#import "Localization.h"
#import "OAColors.h"

@interface OAProfileIconColor()

@property (nonatomic) EOAProfileIconColor profileIconColor;
@property (nonatomic) NSString *name;
@property (nonatomic) int dayColor;
@property (nonatomic) int nightColor;

@end

@implementation OAProfileIconColor

+ (instancetype) withProfileIconColor:(EOAProfileIconColor)profileIconColor
{
    OAProfileIconColor *obj = [[OAProfileIconColor alloc] init];
    if (obj)
    {
        obj.profileIconColor = profileIconColor;
        obj.name = [self.class getName:profileIconColor];
        obj.dayColor = [self.class getDayColor:profileIconColor];
        obj.nightColor = [self.class getNightColor:profileIconColor];
    }

    return obj;
}

- (int) getColor:(BOOL)nightMode
{
    return [self.class getColor:_profileIconColor nightMode:nightMode];
}

+ (NSArray<OAProfileIconColor *> *) values;
{
    return @[ [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_DEFAULT],
              [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_PURPLE],
              [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_GREEN],
              [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_BLUE],
              [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_RED],
              [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_DARK_YELLOW],
              [OAProfileIconColor withProfileIconColor:PROFILE_ICON_COLOR_MAGENTA] ];
}

+ (NSString *) getName:(EOAProfileIconColor)profileIconColor
{
    switch (profileIconColor)
    {
        case PROFILE_ICON_COLOR_DEFAULT:
            return OALocalizedString(@"rendering_value_default_name");
        case PROFILE_ICON_COLOR_PURPLE:
            return OALocalizedString(@"rendering_value_purple_name");
        case PROFILE_ICON_COLOR_GREEN:
            return OALocalizedString(@"rendering_value_green_name");
        case PROFILE_ICON_COLOR_BLUE:
            return OALocalizedString(@"rendering_value_blue_name");
        case PROFILE_ICON_COLOR_RED:
            return OALocalizedString(@"rendering_value_red_name");
        case PROFILE_ICON_COLOR_DARK_YELLOW:
            return OALocalizedString(@"rendering_value_darkyellow_name");
        case PROFILE_ICON_COLOR_MAGENTA:
            return OALocalizedString(@"shared_string_color_magenta");
        default:
            return @"";
    }
}

+ (int) getDayColor:(EOAProfileIconColor)profileIconColor
{
    switch (profileIconColor)
    {
        case PROFILE_ICON_COLOR_DEFAULT:
            return profile_icon_color_blue_light_default;
        case PROFILE_ICON_COLOR_PURPLE:
            return profile_icon_color_purple_light;
        case PROFILE_ICON_COLOR_GREEN:
            return profile_icon_color_green_light;
        case PROFILE_ICON_COLOR_BLUE:
            return profile_icon_color_blue_light;
        case PROFILE_ICON_COLOR_RED:
            return profile_icon_color_red_light;
        case PROFILE_ICON_COLOR_DARK_YELLOW:
            return profile_icon_color_yellow_light;
        case PROFILE_ICON_COLOR_MAGENTA:
            return profile_icon_color_magenta_light;
        default:
            return profile_icon_color_blue_light_default;
    }
}

+ (int) getNightColor:(EOAProfileIconColor)profileIconColor
{
    switch (profileIconColor)
    {
        case PROFILE_ICON_COLOR_DEFAULT:
            return profile_icon_color_blue_dark_default;
        case PROFILE_ICON_COLOR_PURPLE:
            return profile_icon_color_purple_dark;
        case PROFILE_ICON_COLOR_GREEN:
            return profile_icon_color_green_dark;
        case PROFILE_ICON_COLOR_BLUE:
            return profile_icon_color_blue_dark;
        case PROFILE_ICON_COLOR_RED:
            return profile_icon_color_red_dark;
        case PROFILE_ICON_COLOR_DARK_YELLOW:
            return profile_icon_color_yellow_dark;
        case PROFILE_ICON_COLOR_MAGENTA:
            return profile_icon_color_magenta_dark;
        default:
            return profile_icon_color_blue_dark_default;
    }
}

+ (int) getColor:(EOAProfileIconColor)profileIconColor nightMode:(BOOL)nightMode
{
    return nightMode ? [self.class getNightColor:profileIconColor] : [self.class getDayColor:profileIconColor];
}

+ (int) getOutdatedLocationColor:(EOAProfileIconColor)profileIconColor nightMode:(BOOL)nightMode
{
    return nightMode ? profile_icon_color_outdated_dark : profile_icon_color_outdated_light;
}

@end
