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
                        if ([duplicateItem.getName isEqualToString:savedAction.name])
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
        
        if (quickAction)
        {
            NSString *paramsString = object[@"params"];
            NSError *jsonError;
            NSData* paramsData = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:paramsData options:kNilOptions error:&jsonError]];
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
            jsonObject[@"actionType"] = action.actionType.stringId;
            jsonObject[@"params"] = [action getParams];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end
