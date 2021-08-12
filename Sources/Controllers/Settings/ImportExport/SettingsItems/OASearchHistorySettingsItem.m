//
//  OASearchHistorySettingsItem.m
//  OsmAnd Maps
//
//  Created by Paul on 06.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASearchHistorySettingsItem.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"

@interface OASearchHistorySettingsItem ()

@property (nonatomic) NSMutableArray<OAHistoryItem *> *items;
@property (nonatomic) NSMutableArray<OAHistoryItem *> *existingItems;
@property (nonatomic) NSMutableArray<OAHistoryItem *> *appliedItems;

@end

@implementation OASearchHistorySettingsItem
{
    OAHistoryHelper *_searchHistoryHelper;
}

@dynamic existingItems, appliedItems, items;

- (instancetype) initWithItems:(NSArray<OAHistoryItem *> *)items
{
    self = [super initWithItems:items];
    return self;
}

- (void)initialization
{
    [super initialization];
    _searchHistoryHelper = OAHistoryHelper.sharedInstance;
    self.existingItems = [NSMutableArray arrayWithArray:[_searchHistoryHelper getPointsHavingTypes:_searchHistoryHelper.searchTypes limit:0]];
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeSearchHistory;
}

- (NSString *)name
{
    return @"search_history";
}

- (NSString *)publicName
{
    return OALocalizedString(@"search_history");
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (void)apply
{
    NSArray<OAHistoryItem *> *newItems = self.getNewItems;
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        
        // leave the last accessed history entry between the duplicate and the original
        for (OAHistoryItem *duplicate in self.duplicateItems)
        {
            NSString *name = duplicate.name;
            OAHistoryItem *original = [_searchHistoryHelper getPointByName:name];
            if (original && original.date.timeIntervalSince1970 < duplicate.date.timeIntervalSince1970)
            {
                [self.appliedItems removeObject:original];
                [self.appliedItems addObject:duplicate];
            }
        }
        // TODO: Sync search history with Android and replace existing items in history!
//        [_searchHistoryHelper addItemsToHistory:self.appliedItems];
        for (OAHistoryItem *item in self.appliedItems)
             [_searchHistoryHelper addPoint:item];
    }
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (OASettingsItemWriter *)getWriter
{
    return [self getJsonWriter];
}

- (void)readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        double latitude = [object[@"latitude"] doubleValue];
        double longitude = [object[@"longitude"] doubleValue];
        NSString *pointDescription = object[@"pointDescription"];
        
        long lastAccessedTime = [object[@"lastAccessedTime"] longValue];
//        NSString *intervals = object[@"intervals"];
//        NSString *intervalValues = object[@"intervalValues"];
        
        OAPointDescription *pd = [OAPointDescription deserializeFromString:pointDescription l:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
        OAHistoryItem *item = [[OAHistoryItem alloc] initWithPointDescription:pd];
        item.name = pd.name;
        item.iconName = pd.iconName;
        item.latitude = latitude;
        item.longitude = longitude;
        item.date = [NSDate dateWithTimeIntervalSince1970:lastAccessedTime / 1000];
//        historyEntry.setFrequency(intervals, intervalValues);
        [self.items addObject:item];
    }
}

- (BOOL)isDuplicate:(id)item
{
    OAHistoryItem *historyEntry = item;
    NSString *name = historyEntry.name;
    for (OAHistoryItem *entry in self.existingItems)
    {
        if ([entry.name isEqualToString:name]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)shouldShowDuplicates
{
    return NO;
}

- (id)renameItem:(id)item
{
    return item;
}

- (NSDictionary *) getSettingsJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    NSMutableArray *jsonArray = [NSMutableArray new];
    if (self.items.count > 0)
    {
        for (OAHistoryItem *historyEntry in self.items)
        {
            NSMutableDictionary *item = [NSMutableDictionary new];
            item[@"latitude"] = @(historyEntry.latitude);
            item[@"longitude"] = @(historyEntry.longitude);
            item[@"pointDescription"] = [OAPointDescription serializeToString:[[OAPointDescription alloc] initWithType:historyEntry.getPointDescriptionType typeName:historyEntry.typeName name:historyEntry.name]];
            item[@"lastAccessedTime"] = @(historyEntry.date.timeIntervalSince1970 * 1000);
            //                jsonObject.put("intervals", historyEntry.getIntervals());
            //                jsonObject.put("intervalValues", historyEntry.getIntervalsValues());
            [jsonArray addObject:item];
        }
        json[@"items"] = jsonArray;
    }
    return json;
}

@end
