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

@interface OAQuickActionsSettingsItem()

@property (nonatomic) NSMutableArray<OAQuickAction *> *items;
@property (nonatomic) NSMutableArray<OAQuickAction *> *appliedItems;
@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *existingItems;
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
                    for (OAQuickAction *savedAction in self.existingItems)
                        if ([duplicateItem.getName isEqualToString:savedAction.getName])
                            [newActions removeObject:savedAction];
            }
            else
            {
                for (OAQuickAction * duplicateItem in self.duplicateItems)
                    [self renameItem:duplicateItem];
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
            if ([quickAction isKindOfClass:OAMapStyleAction.class])
            {
                NSString *styles = params[quickAction.getListKey];
                if (styles)
                    params[quickAction.getListKey] = [styles componentsSeparatedByString:@","];
            }
            else if ([quickAction isKindOfClass:OASwitchableAction.class])
            {
                NSString *values = params[quickAction.getListKey];
                if (values)
                    params[quickAction.getListKey] = [self parseParamsFromString:values];
            }
            if (name.length > 0)
                [quickAction setName:name];
            [quickAction setParams:params];
            [self.items addObject:quickAction];
        } else {
            [self.warnings addObject:OALocalizedString(@"settings_item_read_error", self.name)];
        }
    }
}

- (void) writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAQuickAction *action in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"name"] = [action hasCustomName] ? [action getName] : @"";
            jsonObject[@"actionType"] = action.getActionTypeId;
            jsonObject[@"params"] = [self adjustParamsForExport:[action getParams] action:action];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

- (NSDictionary *) adjustParamsForExport:(NSDictionary *)params action:(OAQuickAction *)action
{
    if ([action isKindOfClass:OAMapStyleAction.class])
    {
        NSMutableDictionary *paramsCopy = [NSMutableDictionary dictionaryWithDictionary:params];
        NSArray<NSString *> *styles = params[action.getListKey];
        NSMutableString *res = [NSMutableString new];
        if (styles)
        {
            for (NSInteger i = 0; i < (NSInteger) styles.count - 1; i++)
            {
                [res appendString:styles[i]];
                [res appendString:@","];
            }
            [res appendString:styles.lastObject];
            paramsCopy[action.getListKey] = res;
        }
        return paramsCopy;
    }
    else if ([action isKindOfClass:OASwitchableAction.class])
    {
        NSMutableDictionary *paramsCopy = [NSMutableDictionary dictionaryWithDictionary:params];
        NSArray<NSArray<NSString *> *> *values = params[action.getListKey];
        if (values)
        {
            paramsCopy[action.getListKey] = [self paramsToExportArray:values];
        }
        return paramsCopy;
    }
    return params;
}

- (NSArray<NSArray<NSString *> *> *) parseParamsFromString:(NSString *)params
{
    NSMutableArray<NSArray<NSString *> *> *res = [NSMutableArray new];
    NSData *jsonData = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (!error)
    {
        for(NSDictionary *pair in jsonArr)
        {
            NSString *first = pair[@"first"];
            NSString *second = pair[@"second"];
            if (first && second)
                [res addObject:@[first, second]];
        }
    }
    return res;
}

- (NSArray<NSDictionary *> *) paramsToExportArray:(NSArray<NSArray<NSString *> *> *)params
{
    NSMutableArray<NSDictionary *> *res = [NSMutableArray new];
    for (NSArray<NSString *> *pair in params)
    {
        [res addObject:@{@"first" : pair.firstObject, @"second" : pair.lastObject}];
    }
    return res;
}

@end
