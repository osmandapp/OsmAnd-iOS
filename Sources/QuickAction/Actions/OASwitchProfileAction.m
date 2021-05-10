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

#define kNames @"names"
#define kStringKeys @"stringKeys"
#define kIconNames @"iconsNames"
#define kIconColors @"iconsColors"
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
    NSArray<NSString *> *profiles = self.getParams[kStringKeys];
    
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
    NSString *currentProfile = settings.applicationMode.stringKey;
    
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
        [OAAppSettings sharedManager].applicationMode = appMode;
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
                          @"type" : @"OASwitchTableViewCell",
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    NSArray<NSString *> *names = self.getParams[kNames];
    NSArray<NSString *> *stringKeys = self.getParams[kStringKeys];
    NSArray<NSString *> *iconNames = self.getParams[kIconNames];
    NSArray<NSString *> *iconColors = self.getParams[kIconColors];
    NSMutableArray *arr = [NSMutableArray new];

    for (int i = 0; i < names.count; i++)
    {
        [arr addObject:@{
                         @"type" : @"OATitleDescrDraggableCell",
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
            else if ([item[@"type"] isEqualToString:@"OATitleDescrDraggableCell"])
            {
                [names addObject:item[@"title"]];
                [stringKeys addObject:item[@"stringKey"]];
                [iconNames addObject:item[@"img"]];
                [iconColors addObject:item[@"iconColor"]];
            }
        }
    }
    [params setObject:names forKey:kNames];
    [params setObject:stringKeys forKey:kStringKeys];
    [params setObject:iconNames forKey:kIconNames];
    [params setObject:iconColors forKey:kIconColors];
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
    return [self getParams][kNames];
}

- (OAApplicationMode *) getModeForKey:(NSString *)key
{
    return [OAApplicationMode valueOfStringKey:key def:nil];
}

@end

