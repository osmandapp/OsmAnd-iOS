//
//  OASwitchProfileAction.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASwitchProfileAction.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAMapButtonsHelper.h"
#import "OAProfileSelectionBottomSheetViewController.h"
#import "OAButtonTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleDescrDraggableCell.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kProfiles = @"profiles";

static OAQuickActionType *TYPE;

@implementation OASwitchProfileAction
{
    OAAppSettings *_settings;
}

- (instancetype) init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

+ (void)initialize
{
    TYPE = [[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsSwitchProfileActionId
                                           stringId:@"profile.change"
                                                 cl:self.class]
              name:OALocalizedString(@"change_application_profile")]
             iconName:@"ic_custom_manage_profiles"]
            category:EOAQuickActionTypeCategoryNavigation];
}

- (void)execute
{
    NSArray<NSString *> *profiles = self.getParams[[self getListKey]];
    
    if (profiles.count == 0)
        return;
    
    BOOL showDialog = [[self getParams][kDialog] boolValue];
    if (showDialog)
    {
        OAProfileSelectionBottomSheetViewController *bottomSheet = [[OAProfileSelectionBottomSheetViewController alloc] initWithParam:self];
        [bottomSheet show];
        return;
    }
    
    int index = -1;
    NSString *currentProfile = _settings.applicationMode.get.stringKey;
    
    for (int idx = 0; idx < profiles.count; idx++)
    {
        if ([currentProfile isEqualToString:profiles[idx]])
        {
            index = idx;
            break;
        }
    }

    NSMutableArray<NSString *> *nextProfile = [NSMutableArray arrayWithObject:profiles[0]];
    if (index >= 0 && index + 1 < profiles.count)
        nextProfile[0] = profiles[index + 1];
    [self executeWithParams:nextProfile];
}

- (void)executeWithParams:(NSArray<NSString *> *)params
{
    OAApplicationMode *appMode = [self getModeForKey:params.firstObject];
    if (appMode)
        [_settings setApplicationModePref:appMode];
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    return item;
}

- (NSString *)getAddBtnText
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
    return kProfiles;
}

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[
        @{
            @"type" : [OASwitchTableViewCell getCellIdentifier],
            @"key" : kDialog,
            @"title" : OALocalizedString(@"quick_action_interim_dialog"),
            @"value" : @([[self getParams][kDialog] boolValue]),
        },
        @{
            @"footer" : OALocalizedString(@"quick_action_dialog_descr")
        }] forKey:OALocalizedString(@"quick_action_dialog")
    ];
    
    NSArray<NSString *> *stringKeys = [self getParams][[self getListKey]];
    NSMutableArray<NSDictionary *> *arr = [NSMutableArray new];
    
    for (int i = 0; i < stringKeys.count; i++)
    {
        OAApplicationMode *mode = [self getModeForKey:stringKeys[i]];
        if (mode)
        {
            [arr addObject:@{
                @"type" : [OATitleDescrDraggableCell getCellIdentifier],
                @"title" : [mode toHumanString],
                @"stringKey" : stringKeys[i],
                @"img" : [mode getIconName],
                @"iconColor" : @([mode getIconColor])
            }];
        }
    }
    [arr addObject:@{
        @"title" : OALocalizedString(@"shared_string_add_profile"),
        @"type" : [OAButtonTableViewCell getCellIdentifier],
        @"target" : @"addProfile"
    }];

    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"application_profiles")];
    return data;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSMutableArray *stringKeys = [NSMutableArray new];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"key"] isEqualToString:kDialog])
                [params setValue:item[@"value"] forKey:kDialog];
            else if ([item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]])
                [stringKeys addObject:item[@"stringKey"]];
        }
    }
    [params setObject:stringKeys forKey:[self getListKey]];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return stringKeys.count > 0;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_list_descr");
}

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

- (NSArray *)loadListFromParams
{
    return [self getParams][[self getListKey]]; //todo: migrate
}

- (OAApplicationMode *) getModeForKey:(NSString *)key
{
    return [OAApplicationMode valueOfStringKey:key def:nil];
}

@end
