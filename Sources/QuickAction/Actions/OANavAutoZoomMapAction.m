//
//  OANavAutoZoomMapAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavAutoZoomMapAction.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

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
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsNavAutoZoomMapActionId
                                            stringId:@"nav.autozoom"
                                                  cl:self.class]
               name:OALocalizedString(@"quick_action_auto_zoom")]
              iconName:@"ic_navbar_search"]
             category:EOAQuickActionTypeCategoryNavigation]
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

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
