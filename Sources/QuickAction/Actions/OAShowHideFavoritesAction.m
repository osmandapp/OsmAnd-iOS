//
//  OAShowHideFavoritesAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideFavoritesAction.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideFavoritesAction
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideFavoritesActionId
                                            stringId:@"favorites.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"shared_string_favorites")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_favorites"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
