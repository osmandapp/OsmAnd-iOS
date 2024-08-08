//
//  OAShowHideCycleRoutesAction.m
//  OsmAnd
//
//  Created by Max Kojin on 08/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAShowHideCycleRoutesAction.h"

#import "OAAppSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideCycleRoutesAction
{
    OAAppSettings *_settings;
    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_routesParameter;
    OAMapStyleParameter *_cycleNode;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideCycleRoutesActionId
                                            stringId:@"cycle.routes.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"rendering_attr_showCycleRoutes_name")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_action_bicycle_dark"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _styleSettings = [OAMapStyleSettings sharedInstance];
    _routesParameter = [_styleSettings getParameter:@"showCycleRoutes"];
    _cycleNode =  [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
}

- (BOOL) isEnabled
{
    return _routesParameter.storedValue.length > 0 && [_routesParameter.storedValue isEqualToString:@"true"];
}

- (void)execute
{
    NSString *newValue = [self isEnabled] ? @"false" : @"true";
    _routesParameter.value = newValue;
    [_styleSettings save:_routesParameter];
    if (_cycleNode)
    {
        _cycleNode.value = newValue;
        [_styleSettings save:_cycleNode];
    }
}

- (BOOL)isActionWithSlash
{
    return [self isEnabled];
}

- (NSString *)getActionStateName
{
    NSString *actionName = OALocalizedString([self isActionWithSlash] ? @"shared_string_hide" : @"shared_string_show");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), actionName, OALocalizedString(@"rendering_attr_showCycleRoutes_name")];
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
