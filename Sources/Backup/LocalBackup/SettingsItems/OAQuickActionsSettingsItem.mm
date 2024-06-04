//
//  OAQuickActionsSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAQuickActionsSettingsItem.h"
#import "OAQuickActionsSettingsItemReader.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAMapButtonsHelper.h"
#import "OAUnsupportedAction.h"
#import "OAMapStyleAction.h"
#import "OASwitchableAction.h"
#import "OASwitchProfileAction.h"
#import "OsmAnd_Maps-Swift.h"

#define APPROXIMATE_QUICK_ACTION_SIZE_BYTES 135

@implementation OAQuickActionsSettingsItem
{
    OAMapButtonsHelper *_mapButtonsHelper;
    OAQuickActionButtonState *_buttonState;
}

@dynamic type, name;

- (instancetype)initWithBaseItem:(OASettingsItem *)baseItem buttonState:(OAQuickActionButtonState *)buttonState
{
    self = [super initWithBaseItem:baseItem];
    if (self)
    {
        _buttonState = buttonState;
    }
    return self;
}

- (void)initialization
{
    [super initialization];

    _mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeQuickActions;
}

- (OAQuickActionButtonState *)getButtonState
{
    return _buttonState;
}

- (void)renameButton
{
    NSString *name = [_buttonState getName];
    OAQuickActionButtonState *newButtonState = [_mapButtonsHelper createNewButtonState];
    [newButtonState setName:[_mapButtonsHelper generateUniqueButtonName:name]];
    [newButtonState setEnabled:[_buttonState isEnabled]];
    _buttonState = newButtonState;
}

- (long)localModifiedTime
{
    return [_buttonState getLastModifiedTime];
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [_buttonState setLastModifiedTime:localModifiedTime];
}

- (BOOL)exists
{
    return [_mapButtonsHelper getButtonStateById:_buttonState.id] != nil;
}

- (void)apply
{
    if ([self exists])
    {
        if (self.shouldReplace)
        {
            OAQuickActionButtonState *state = [_mapButtonsHelper getButtonStateById:_buttonState.id];
            if (state)
                [_mapButtonsHelper removeQuickActionButtonState:state];
        }
        else
        {
            [self renameButton];
        }
    }
    [_mapButtonsHelper addQuickActionButtonState:_buttonState];
}

- (BOOL)shouldReadOnCollecting
{
    return YES;
}

- (long)getEstimatedItemSize:(id)item
{
    return _buttonState.quickActions.count * APPROXIMATE_QUICK_ACTION_SIZE_BYTES;
}

- (NSString *)name
{
    return [_buttonState getName];
}

- (NSString *)getPublicName
{
    return [_buttonState hasCustomName] ? [_buttonState getName] : OALocalizedString(@"shared_string_quick_actions");
}

- (OASettingsItemReader *)getReader
{
    return [[OAQuickActionsSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return self.getJsonWriter;
}

- (void)readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray *itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;

    if ([[OASettingsHelper sharedInstance] getCurrentBackupVersion] <= OAMigrationManager.importExportVersionMigration2)
        itemsJson = [[OAMigrationManager shared] changeJsonMigrationToV3:itemsJson];

    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray array];
    for (id object in itemsJson)
    {
        NSString *name = object[@"name"];
        NSString *actionType = object[@"actionType"];
        NSString *type = object[@"type"];
        OAQuickAction *quickAction = nil;
        if (actionType)
            quickAction = [_mapButtonsHelper newActionByStringType:actionType];
        else if (type)
            quickAction = [_mapButtonsHelper newActionByType:type.integerValue];

        if (!quickAction && actionType)
            quickAction = [[OAUnsupportedAction alloc] initWithActionTypeId:actionType];

        if (quickAction)
        {
            NSString *paramsString = object[@"params"];
            NSError *jsonError;
            NSData* paramsData = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:paramsData options:kNilOptions error:&jsonError]];

            if ([quickAction isKindOfClass:OASwitchProfileAction.class])
            {
                OASwitchProfileAction *switchProfileAction = (OASwitchProfileAction *) quickAction;
                id stringKeys = params[OAQuickActionSerializer.kSwitchProfileStringKeys];
                if (!stringKeys || params[[switchProfileAction getListKey]])
                {
                    stringKeys = params[[switchProfileAction getListKey]];
                    [params removeObjectForKey:[switchProfileAction getListKey]];
                }
                if (stringKeys)
                    params[OAQuickActionSerializer.kSwitchProfileStringKeys] = [NSJSONSerialization JSONObjectWithData:[stringKeys dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];

                [OAQuickActionSerializer readSwitchProfileAction:OAQuickActionSerializer.kSwitchProfileNames params:params];
                [OAQuickActionSerializer readSwitchProfileAction:OAQuickActionSerializer.kSwitchProfileIconNames params:params];
                [OAQuickActionSerializer readSwitchProfileAction:OAQuickActionSerializer.kSwitchProfileIconColors params:params];
            }
            else
            {
                NSString *values = params[quickAction.getListKey];
                if (values)
                {
                    if ([quickAction isKindOfClass:OAMapStyleAction.class])
                        params[[((OAMapStyleAction *) quickAction) getListKey]] = [values componentsSeparatedByString:@","];
                    else if ([quickAction isKindOfClass:OASwitchableAction.class])
                        params[[((OASwitchableAction *) quickAction) getListKey]] = [OAQuickActionSerializer parseParamsFromString:values];
                }
            }
            if (name.length > 0)
                [quickAction setName:name];
            [quickAction setParams:params];
            [quickActions addObject:quickAction];
        }
        else
        {
            [self.warnings addObject:OALocalizedString(@"settings_item_read_error", name)];
        }
    }
    [_mapButtonsHelper updateQuickActions:_buttonState actions:quickActions];
    [_mapButtonsHelper updateActiveActions];
}

- (void)writeToJson:(id)json
{
    [super writeToJson:json];
    NSMutableDictionary<NSString *, NSString *> *jsonObject = [NSMutableDictionary dictionary];
    jsonObject[@"id"] = _buttonState.id;
    jsonObject[@"name"] = [_buttonState hasCustomName] ? [_buttonState getName] : @"";
    jsonObject[@"enabled"] = @([_buttonState isEnabled]).stringValue;
    json[@"buttonState"] = jsonObject;
}

- (void)writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (_buttonState.quickActions.count > 0)
    {
        for (OAQuickAction *action in _buttonState.quickActions)
        {
            NSMutableDictionary<NSString *, NSString *> *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"name"] = [action hasCustomName] ? [action getName] : @"";
            jsonObject[@"actionType"] = action.actionType.stringId;
            NSDictionary *params = [OAQuickActionSerializer adjustParamsForExport:[action getParams] action:action];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
            jsonObject[@"params"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end
