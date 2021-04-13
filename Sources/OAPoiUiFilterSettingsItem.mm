//
//  OAPoiUiFilterSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPoiUiFilterSettingsItem.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAPOIHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OAQuickSearchHelper.h"

#define kNAME_KEY @"name"
#define kFILTER_ID_KEY @"filterId"
#define kACCEPTER_TYPES_KEY @"acceptedTypes"

@interface OAPoiUiFilterSettingsItem()

@property (nonatomic) NSMutableArray<OAPOIUIFilter *> *items;
@property (nonatomic) NSMutableArray<OAPOIUIFilter *> *appliedItems;
@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *existingItems;

@end

@implementation OAPoiUiFilterSettingsItem
{
    OAPOIHelper *_helper;
    OAPOIFiltersHelper *_filtersHelper;
}

@dynamic items, appliedItems, existingItems;

- (void) initialization
{
    [super initialization];

    _helper = [OAPOIHelper sharedInstance];
    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    self.existingItems = [_filtersHelper getUserDefinedPoiFilters:NO].mutableCopy;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypePoiUIFilters;
}

- (void) apply
{
    NSArray<OAPOIUIFilter *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        for (OAPOIUIFilter *duplicate in self.duplicateItems)
            [self.appliedItems addObject:self.shouldReplace ? duplicate : [self renameItem:duplicate]];
        
        for (OAPOIUIFilter *filter in self.appliedItems)
            [_filtersHelper createPoiFilter:filter];

        [[OAQuickSearchHelper instance] refreshCustomPoiFilters];
    }
}

- (BOOL) isDuplicate:(OAPOIUIFilter *)item
{
    NSString *savedName = item.name;
    for (OAPOIUIFilter *filter in self.existingItems)
        if ([filter.name isEqualToString:savedName])
            return YES;

    return NO;
}

- (OAPOIUIFilter *) renameItem:(OAPOIUIFilter *)item
{
    int number = 0;
    while (true)
    {
        number++;
        OAPOIUIFilter *renamedItem = [[OAPOIUIFilter alloc] initWithFilter:item name:[NSString stringWithFormat:@"%@_%d", item.name, number] filterId:[NSString stringWithFormat:@"%@_%d", item.filterId, number]];
        if (![self isDuplicate:renamedItem])
            return renamedItem;
    }
}

- (NSString *) name
{
    return @"poi_ui_filters";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        NSString *name = object[kNAME_KEY];
        NSString *filterId = object[kFILTER_ID_KEY];
        NSString *acceptedTypes = object[kACCEPTER_TYPES_KEY];

        NSDictionary<NSString *, NSMutableSet<NSString *> *> *array = [NSJSONSerialization JSONObjectWithData:[acceptedTypes dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypesDone = [NSMapTable strongToStrongObjectsMapTable];

        for (NSString *key in array.allKeys)
        {
            NSMutableSet<NSString *> *value = array[key];
            OAPOICategory *a = [_helper getPoiCategoryByName:key];
            [acceptedTypesDone setObject:value forKey:a];
        }

        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:name filterId:filterId acceptedTypes:acceptedTypesDone];
        [self.items addObject:filter];
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAPOIUIFilter *filter in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"name"] = filter.name;
            jsonObject[@"filterId"] = filter.filterId;
            jsonObject[@"acceptedTypes"] = [filter getAcceptedTypes];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end

