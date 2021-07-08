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
#import "OAQuickActionRegistry.h"
#import "OAQuickActionType.h"

#import "OAUnsupportedAction.h"
#import "OAMapStyleAction.h"
#import "OASwitchableAction.h"
#import "OASwitchProfileAction.h"

@interface OAQuickActionsSettingsItem()

@property (nonatomic) NSMutableArray<OAQuickAction *> *items;
@property (nonatomic) NSMutableArray<OAQuickAction *> *appliedItems;
@property (nonatomic) NSMutableArray<OAQuickAction *> *existingItems;
@property (nonatomic) NSMutableArray<NSString *> *warnings;

@end

@implementation OAQuickActionsSettingsItem
{
    OAQuickActionRegistry *_actionsRegistry;
}

@dynamic items, appliedItems, existingItems, warnings;

- (void) initialization
{
    [super initialization];

    _actionsRegistry = [OAQuickActionRegistry sharedInstance];
    self.existingItems = [_actionsRegistry getQuickActions].mutableCopy;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeQuickActions;
}

- (BOOL) isDuplicate:(OAQuickAction *)item
{
    return ![_actionsRegistry isNameUnique:item];
}

- (OAQuickAction *) renameItem:(OAQuickAction *)item
{
    return [_actionsRegistry generateUniqueName:item];
}

- (void) apply
{
    NSArray<OAQuickAction *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        NSMutableArray<OAQuickAction *> *newActions = [NSMutableArray arrayWithArray:self.existingItems];
        if (self.duplicateItems.count > 0)
        {
            if (self.shouldReplace)
            {
                for (OAQuickAction *duplicateItem in self.duplicateItems)
                {
                    for (OAQuickAction *savedAction in self.existingItems)
                    {
                        if ([duplicateItem.getName isEqualToString:savedAction.getName])
                            [newActions removeObject:savedAction];
                    }
                }
            }
            else
            {
                for (OAQuickAction * duplicateItem in self.duplicateItems)
                {
                    [self renameItem:duplicateItem];
                }
            }
            [self.appliedItems addObjectsFromArray:self.duplicateItems];
        }
        [newActions addObjectsFromArray:self.appliedItems];
        [_actionsRegistry updateQuickActions:newActions];
        [_actionsRegistry updateActionTypes];
        [_actionsRegistry.quickActionListChangedObservable notifyEvent];
    }
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (NSString *) name
{
    return @"quick_actions";
}

- (OASettingsItemReader *) getReader
{
    return [[OAQuickActionsSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return self.getJsonWriter;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;

    for (id object in itemsJson)
    {
        NSString *name = object[@"name"];
        NSString *actionType = object[@"actionType"];
        NSString *type = object[@"type"];
        OAQuickAction *quickAction = nil;
        if (actionType)
            quickAction = [_actionsRegistry newActionByStringType:actionType];
        else if (type)
            quickAction = [_actionsRegistry newActionByType:type.integerValue];

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
                id stringKeys = params[kSwitchProfileStringKeys];
                if (!stringKeys || params[quickAction.getListKey])
                {
                    stringKeys = params[quickAction.getListKey];
                    [params removeObjectForKey:quickAction.getListKey];
                }
                if (stringKeys)
                    params[kSwitchProfileStringKeys] = [NSJSONSerialization JSONObjectWithData:[stringKeys dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];

                [self readSwitchProfileAction:kSwitchProfileNames params:params];
                [self readSwitchProfileAction:kSwitchProfileIconNames params:params];
                [self readSwitchProfileAction:kSwitchProfileIconColors params:params];
            }
            else
            {
                NSString *values = params[quickAction.getListKey];
                if (values)
                {
                    if ([quickAction isKindOfClass:OAMapStyleAction.class])
                        params[quickAction.getListKey] = [values componentsSeparatedByString:@","];
                    else if ([quickAction isKindOfClass:OASwitchableAction.class])
                        params[quickAction.getListKey] = [self parseParamsFromString:values];
                }
            }
            if (name.length > 0)
                [quickAction setName:name];
            [quickAction setParams:params];
            [self.items addObject:quickAction];
        }
        else
        {
            [self.warnings addObject:OALocalizedString(@"settings_item_read_error", self.name)];
        }
    }
}

- (NSDictionary *) getSettingsJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAQuickAction *action in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"name"] = [action hasCustomName] ? [action getName] : @"";
            jsonObject[@"actionType"] = action.getActionTypeId;
            NSDictionary *params = [self adjustParamsForExport:[action getParams] action:action];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
            jsonObject[@"params"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
    return json;
}


- (NSDictionary *) adjustParamsForExport:(NSDictionary *)params action:(OAQuickAction *)action
{
    if ([action isKindOfClass:OAMapStyleAction.class])
    {
        NSMutableDictionary *paramsCopy = [NSMutableDictionary dictionaryWithDictionary:params];
        NSArray<NSString *> *values = params[action.getListKey];
        NSMutableString *res = [NSMutableString new];
        if (values && values.count > 0)
        {
            for (NSString *value in values)
            {
                [res appendString:value];
                if (![value isEqualToString:values.lastObject])
                    [res appendString:@","];
            }
        }
        paramsCopy[action.getListKey] = res;
        return paramsCopy;
    }
    else if ([action isKindOfClass:OASwitchableAction.class])
    {
        NSMutableDictionary *paramsCopy = [NSMutableDictionary dictionaryWithDictionary:params];
        NSArray *values = params[action.getListKey];
        if (values && values.count > 0)
        {
            NSData *data = [self paramsToExportArray:values];
            if (data)
                paramsCopy[action.getListKey] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }

        if ([action isKindOfClass:OASwitchProfileAction.class])
        {
            if (!values || paramsCopy[kSwitchProfileStringKeys])
            {
                values = paramsCopy[kSwitchProfileStringKeys];
                [paramsCopy removeObjectForKey:kSwitchProfileStringKeys];
                paramsCopy[action.getListKey] = [[NSString alloc] initWithData:[self paramsToExportArray:values] encoding:NSUTF8StringEncoding];
            }
            [self writeSwitchProfileAction:kSwitchProfileNames params:params paramsCopy:paramsCopy];
            [self writeSwitchProfileAction:kSwitchProfileIconNames params:params paramsCopy:paramsCopy];
            [self writeSwitchProfileAction:kSwitchProfileIconColors params:params paramsCopy:paramsCopy];
        }

        return paramsCopy;
    }
    return params;
}

- (NSArray<NSArray<NSString *> *> *) parseParamsFromString:(NSString *)params
{
    NSData *jsonData = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (!error)
    {
        if ([jsonArr.firstObject isKindOfClass:[NSDictionary class]])
        {
            NSMutableArray<NSArray<NSString *> *> *res = [NSMutableArray new];
            for (NSDictionary *pair in jsonArr)
            {
                NSString *first = pair[@"first"];
                NSString *second = pair[@"second"];
                if (first && second)
                    [res addObject:@[first, second]];
            }
            return res;
        }
        return jsonArr;
    }
    return [NSArray new];
}

- (NSData *) paramsToExportArray:(id)params
{
    if ([params isKindOfClass:[NSArray class]])
    {
        NSArray *array = params;
        if (array.count > 0)
        {
            if ([array.firstObject isKindOfClass:[NSArray<NSString *> class]])
            {
                NSMutableArray<NSDictionary *> *res = [NSMutableArray new];
                for (NSArray<NSString *> *pair in array)
                {
                    [res addObject:@{@"first": pair.firstObject, @"second": pair.lastObject}];
                }
                array = res;
            }
            else if ([array.firstObject isKindOfClass:[NSNumber class]])
            {
                NSMutableArray<NSString *> *res = [NSMutableArray new];
                for (NSNumber *param in array)
                {
                    [res addObject:param.stringValue];
                }
                array = res;
            }
        }
        return [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    }
    return nil;
}

- (void)readSwitchProfileAction:(NSString *)key params:(NSMutableDictionary *)params
{
    NSMutableString *values = params[key];
    if (values)
    {
        params[key] = [NSJSONSerialization JSONObjectWithData:[values dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    }
    else
    {
        values = [NSMutableString new];
        NSArray *stringKeys = params[kSwitchProfileStringKeys];
        if (stringKeys && stringKeys.count > 0)
        {
            for (NSString *stringKey in stringKeys)
            {
                OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:stringKey def:OAApplicationMode.DEFAULT];
                if ([key isEqualToString:kSwitchProfileNames])
                    [values appendString:mode.name];
                else if ([key isEqualToString:kSwitchProfileIconNames])
                    [values appendString:mode.getIconName];
                else if ([key isEqualToString:kSwitchProfileIconColors])
                    [values appendString:@(mode.getIconColor).stringValue];

                if (![stringKey isEqualToString:stringKeys.lastObject])
                    [values appendString:@","];
            }
        }
        params[key] = [values componentsSeparatedByString:@","];
    }
}


- (void)writeSwitchProfileAction:(NSString *)key params:(NSDictionary *)params paramsCopy:(NSMutableDictionary *)paramsCopy
{
    NSArray *values = params[key];
    if (values && values.count > 0)
    {
        NSData *data = [self paramsToExportArray:values];
        if (data)
            paramsCopy[key] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

@end
