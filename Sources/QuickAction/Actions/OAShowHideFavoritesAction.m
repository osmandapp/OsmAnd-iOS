//
//  OAShowHideFavoritesAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideFavoritesAction.h"
#import "OAAppSettings.h"

@implementation OAShowHideFavoritesAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeShowFavorite];
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

@end
