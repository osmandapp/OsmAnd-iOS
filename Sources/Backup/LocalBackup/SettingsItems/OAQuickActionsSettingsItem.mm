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
#import "OAShowHidePoiAction.h"
#import "OsmAnd_Maps-Swift.h"

#define APPROXIMATE_QUICK_ACTION_SIZE_BYTES 135

@implementation OAQuickActionsSettingsItem
{
    OAMapButtonsHelper *_mapButtonsHelper;
    QuickActionButtonState *_buttonState;
}

@dynamic type, name;

- (instancetype)initWithBaseItem:(OASettingsItem *)baseItem buttonState:(QuickActionButtonState *)buttonState
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

- (QuickActionButtonState *)getButtonState
{
    return _buttonState;
}

- (void)renameButton
{
    NSString *name = [_buttonState getName];
    QuickActionButtonState *newButtonState = [_mapButtonsHelper createNewButtonState];
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
            QuickActionButtonState *state = [_mapButtonsHelper getButtonStateById:_buttonState.id];
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

- (long)getEstimatedItemSize:(id)item
{
    return _buttonState.quickActions.count * APPROXIMATE_QUICK_ACTION_SIZE_BYTES;
}

- (NSString *)name
{
    return _buttonState.id;
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

- (void)readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [self readButtonState:json];
    [super readFromJson:json error:error];
}

- (void)readButtonState:(id)json
{
    @try {
        id object = json[@"buttonState"];
        if (object)
        {
            NSString *id = object[@"id"];
            _buttonState = [[QuickActionButtonState alloc] initWithId:id];
            [_buttonState setName:object[@"name"]];
            [_buttonState setEnabled:[object[@"enabled"] isKindOfClass:NSNumber.class]
                ? [object[@"enabled"] boolValue]
                : [object[@"enabled"] isEqualToString:@"true"] ? YES : NO];
        }
        else
        {
            _buttonState = [[QuickActionButtonState alloc] initWithId:QuickActionButtonState.defaultButtonId];
        }
    }
    @catch (NSException *e)
    {
        [self.warnings addObject:[NSString stringWithFormat:OALocalizedString(@"settings_item_read_error"), [OASettingsItemType typeName:self.type]]];
        @throw [NSException exceptionWithName:@"Json parse error" reason:e.reason userInfo:nil];
    }
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
            [self.class parseParams:object[@"params"] quickAction:quickAction];
            if (name.length > 0)
                [quickAction setName:name];
            [quickActions addObject:quickAction];
        }
        else
        {
            [self.warnings addObject:[NSString stringWithFormat:OALocalizedString(@"settings_item_read_error"), name]];
        }
    }
    [_mapButtonsHelper updateQuickActions:_buttonState actions:quickActions];
    [_mapButtonsHelper updateActiveActions];
}

+ (void)parseParams:(NSString *)paramsString quickAction:(OAQuickAction *)quickAction
{
    NSData *paramsData = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:paramsData options:kNilOptions error:nil];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:json];

    if ([quickAction isKindOfClass:OASwitchableAction.class])
    {
        [self parseParamsWithKey:[quickAction getListKey] params:params toString:NO];
        if ([quickAction isKindOfClass:OASwitchProfileAction.class])
        {
            [params removeObjectForKey:@"names"];
            [params removeObjectForKey:@"iconsNames"];
            [params removeObjectForKey:@"iconsColors"];
        }
    }
    else if ([quickAction isKindOfClass:OAShowHidePoiAction.class])
    {
        [self parseParamsWithKey:kFilters params:params toString:YES];
    }

    [quickAction setParams:params];
}

+ (void)parseParamsWithKey:(NSString *)key params:(NSMutableDictionary *)params toString:(BOOL)toString
{
    NSString *values = params[key];
    if (values)
    {
        NSArray *value = [QuickActionSerializer parseParamsFromString:values];
        params[key] = toString && value.count > 0 && [value.firstObject isKindOfClass:NSString.class] ? [value componentsJoinedByString:@","] : value;
    }
}

- (void)writeToJson:(id)json
{
    [super writeToJson:json];
    NSMutableDictionary<NSString *, NSString *> *jsonObject = [NSMutableDictionary dictionary];
    jsonObject[@"id"] = _buttonState.id;
    jsonObject[@"name"] = [_buttonState hasCustomName] ? [_buttonState getName] : @"";
    jsonObject[@"enabled"] = [_buttonState isEnabled] ? @"true" : @"false";
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
            jsonObject[@"actionType"] = [action getActionTypeId];
            NSDictionary *params = [QuickActionSerializer adjustParamsForExport:[action getParams] action:action];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
            jsonObject[@"params"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end
