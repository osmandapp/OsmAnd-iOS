//
//  OAHistorySettingsItem.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 25/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAHistorySettingsItem.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"

static const NSInteger APPROXIMATE_SEARCH_HISTORY_SIZE_BYTES = 320;

@implementation OAHistorySettingsItem
{
    OAHistoryHelper *_searchHistoryHelper;
}

@dynamic existingItems, appliedItems, items;

- (instancetype) initWithItems:(NSArray<OAHistoryItem *> *)items
{
    self = [super init];
    if (self)
    {
        [self initialization];
        self.items = items.mutableCopy;
    }
    return self;
}

- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self initialization];
        NSError *readError;
        [self readFromJson:json error:&readError];
        if (readError)
        {
            if (error)
                *error = readError;
            return nil;
        }
    }
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
    return @"";
}

- (NSString *)getPublicName
{
    return @"";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (long)getEstimatedItemSize:(id)item
{
    return APPROXIMATE_SEARCH_HISTORY_SIZE_BYTES;
}

- (long)localModifiedTime
{
    return _searchHistoryHelper.getMarkersHistoryLastModifiedTime;
}

- (void)setLocalModifiedTime:(long)lastModifiedTime
{
    [_searchHistoryHelper setMarkersHistoryLastModifiedTime:lastModifiedTime];
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
            OAHistoryItem *original = [_searchHistoryHelper getPointByName:duplicate.name fromNavigation:duplicate.fromNavigation];
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
//        HistorySource source = HistorySource.getHistorySourceByName(object.optString("source"));
        BOOL fromNavigation = [object[@"fromNavigation"] boolValue];

        OAPointDescription *pd = [OAPointDescription deserializeFromString:pointDescription l:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
        OAHistoryItem *item = [[OAHistoryItem alloc] initWithPointDescription:pd];
        item.name = pd.name;
        item.iconName = pd.iconName;
        item.latitude = latitude;
        item.longitude = longitude;
        item.date = [NSDate dateWithTimeIntervalSince1970:lastAccessedTime / 1000];
//        historyEntry.setFrequency(intervals, intervalValues);
        item.fromNavigation = fromNavigation;

        [self.items addObject:item];
    }
}

- (BOOL)isDuplicate:(id)item
{
    OAHistoryItem *historyEntry = item;
    for (OAHistoryItem *entry in self.existingItems)
    {
        if ([entry.name isEqualToString:historyEntry.name] && entry.fromNavigation == historyEntry.fromNavigation)
            return YES;
    }
    return NO;
}

- (void)deleteItem:(OAHistoryItem *)item
{
}

- (BOOL)shouldShowDuplicates
{
    return NO;
}

- (id)renameItem:(id)item
{
    return item;
}

- (void)writeItemsToJson:(id)json
{
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
            //                jsonObject.put("source", historyEntry.getSource().name());
            
            //android don't have this line
            item[@"fromNavigation"] = @(historyEntry.fromNavigation);
            
            [jsonArray addObject:item];
        }
        json[@"items"] = jsonArray;
    }
}

@end
