//
//  OAShowHideFavoritesAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideFavoritesAction.h"
#import "OAAppSettings.h"
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideFavoritesAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingShowFavorites:!settings.mapSettingShowFavorites];
}

- (BOOL)isActionWithSlash
{
    return [OAAppSettings sharedManager].mapSettingShowFavorites;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"fav_hide") : OALocalizedString(@"fav_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:4 stringId:@"favorites.showhide" class:self.class name:OALocalizedString(@"toggle_fav") category:CONFIGURE_MAP iconName:@"ic_custom_favorites" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
