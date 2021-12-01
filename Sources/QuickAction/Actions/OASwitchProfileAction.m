//
//  OASwitchProfileAction.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASwitchProfileAction.h"
#import "OAQuickActionType.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAQuickActionRegistry.h"
#import "OAProfileSelectionBottomSheetViewController.h"
#import "OAButtonCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleDescrDraggableCell.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"

#define KEY_PROFILES @"profiles"

static OAQuickActionType *TYPE;

@implementation OASwitchProfileAction

- (instancetype) init
{
    self = [super initWithActionType:self.class.TYPE];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSArray<NSString *> *profiles = self.getParams[kSwitchProfileStringKeys];
    
    if (profiles.count == 0)
        return;
    
    BOOL showDialog = [[self getParams][KEY_DIALOG] boolValue];
    if (showDialog)
    {
        OAProfileSelectionBottomSheetViewController *bottomSheet = [[OAProfileSelectionBottomSheetViewController alloc] initWithParam:self];
        [bottomSheet show];
        return;
    }
    
    int index = -1;
    NSString *currentProfile = settings.applicationMode.get.stringKey;
    
    for (int idx = 0; idx < profiles.count; idx++)
    {
        if ([currentProfile isEqualToString:profiles[idx]])
        {
            index = idx;
            break;
        }
    }
    
    NSString *nextProfile = profiles[0];
    if (index >= 0 && index + 1 < profiles.count)
        nextProfile = profiles[index + 1];
    
    [self executeWithParams:nextProfile];
}

- (void)executeWithParams:(NSString *)params
{
    OAApplicationMode *appMode = [self getModeForKey:params];
    if (appMode)
    {
        [OAAppSettings.sharedManager setApplicationModePref:appMode];
        [OARootViewController.instance.mapPanel setMapElevationAngle:[[OsmAndApp instance].data.mapLastViewedState elevationAngle:appMode]];
    }
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"shared_string_add_profile");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"change_application_profile");
}

- (NSString *)getListKey
{
    return KEY_PROFILES;
}

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : [OASwitchTableViewCell getCellIdentifier],
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    NSArray<NSString *> *names = self.getParams[kSwitchProfileNames];
    NSArray<NSString *> *stringKeys = self.getParams[kSwitchProfileStringKeys];
    NSArray<NSString *> *iconNames = self.getParams[kSwitchProfileIconNames];
    NSArray<NSString *> *iconColors = self.getParams[kSwitchProfileIconColors];
    NSMutableArray *arr = [NSMutableArray new];

    for (int i = 0; i < names.count; i++)
    {
        [arr addObject:@{
                         @"type" : [OATitleDescrDraggableCell getCellIdentifier],
                         @"title" : names[i] ? names[i] : @"",
                         @"stringKey" : stringKeys[i] ? stringKeys[i] : @"",
                         @"img" : iconNames[i] ? iconNames[i] : @"",
                         @"iconColor" : iconColors[i] ? iconColors[i] : @(color_chart_orange)
                         }];
    }
    [arr addObject:@{
                     @"title" : OALocalizedString(@"shared_string_add_profile"),
                     @"type" : [OAButtonCell getCellIdentifier],
                     @"target" : @"addProfile"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"app_profiles")];
    return data;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *stringKeys = [NSMutableArray new];
    NSMutableArray *iconNames = [NSMutableArray new];
    NSMutableArray *iconColors = [NSMutableArray new];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
            {
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
            }
            else if ([item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]])
            {
                [names addObject:item[@"title"]];
                [stringKeys addObject:item[@"stringKey"]];
                [iconNames addObject:item[@"img"]];
                [iconColors addObject:item[@"iconColor"]];
            }
        }
    }
    [params setObject:names forKey:kSwitchProfileNames];
    [params setObject:stringKeys forKey:kSwitchProfileStringKeys];
    [params setObject:iconNames forKey:kSwitchProfileIconNames];
    [params setObject:iconColors forKey:kSwitchProfileIconColors];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return names.count > 0;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_list_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:32 stringId:@"profile.change" class:self.class name:OALocalizedString(@"change_application_profile") category:NAVIGATION iconName:@"ic_custom_manage_profiles" secondaryIconName:nil];

    return TYPE;
}

- (NSArray *)loadListFromParams
{
    return [self getParams][kSwitchProfileNames];
}

- (OAApplicationMode *) getModeForKey:(NSString *)key
{
    return [OAApplicationMode valueOfStringKey:key def:nil];
}

@end
