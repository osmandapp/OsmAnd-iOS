//
//  OAShowHideFavoritesAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideFavoritesAction.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideFavoritesAction
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)execute
{
    [_settings setShowFavorites:![_settings.mapSettingShowFavorites get]];
}

- (BOOL)isActionWithSlash
{
    return _settings.mapSettingShowFavorites.get;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"fav_hide") : OALocalizedString(@"fav_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideFavoritesActionId stringId:@"favorites.showhide" cl:self.class] name:OALocalizedString(@"toggle_fav")] iconName:@"ic_custom_favorites"]  category:EOAQuickActionTypeCategoryConfigureMap] nonEditable];
    return TYPE;
}

@end
