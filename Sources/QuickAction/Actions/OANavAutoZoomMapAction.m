//
//  OANavAutoZoomMapAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavAutoZoomMapAction.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavAutoZoomMapAction
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavAutoZoomMapActionId
                                            stringId:@"nav.autozoom"
                                                  cl:self.class]
               name:OALocalizedString(@"quick_action_auto_zoom")]
              nameAction:OALocalizedString(@"quick_action_verb_turn_on_off")]
              iconName:@"ic_navbar_search"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)execute
{
    [_settings.autoZoomMap set:![_settings.autoZoomMap get]];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_autozoom_descr");
}

- (BOOL)isActionWithSlash
{
    return [_settings.autoZoomMap get];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"auto_zoom_off") : OALocalizedString(@"auto_zoom_on");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
