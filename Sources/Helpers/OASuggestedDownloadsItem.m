//
//  OASuggestedDownloadsItem.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASuggestedDownloadsItem.h"
#import "OAWorldRegion.h"
#import "OACustomRegion.h"
#import "OACustomPlugin.h"

@implementation OASuggestedDownloadsItem

- (instancetype) initWithScopeId:(NSString *)scopeId searchType:(NSString *)searchType names:(NSArray<NSString *> *)names limit:(NSInteger)limit
{
    self = [super init];
    if (self)
    {
        _scopeId = scopeId;
        _searchType = searchType;
        _names = names;
        _limit = limit;
    }
    return self;
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeSuggestedDownloads;
}

- (NSString *)name
{
    return @"suggested_downloads";
}

- (NSString *)publicName
{
    return @"suggested_downloads";
}

- (void)readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    if (!json[@"items"])
        return;
    
    if (!_items)
        _items = [NSMutableArray new];
    
    NSArray *jsonArr = json[@"items"];
    
    for (int i = 0; i < jsonArr.count; i++)
    {
        id object = jsonArr[i];
        NSString *scopeId = object[@"scope-id"] ? object[@"scope-id"] : @"";
        NSString *searchType = object[@"search-type"] ? object[@"search-type"] : @"";
        NSInteger limit = object[@"limit"] ? [object[@"limit"] integerValue] : -1;
        
        NSMutableArray<NSString *> *names = [NSMutableArray new];
        if (object[@"names"])
        {
            NSMutableArray *namesArray = object[@"names"];
            for (int j = 0; j < namesArray.count; j++)
            {
                [names addObject:namesArray[j]];
            }
        }
        OASuggestedDownloadsItem *suggestedDownload = [[OASuggestedDownloadsItem alloc] initWithScopeId:scopeId searchType:searchType names:names limit:limit];
        [_items addObject:suggestedDownload];
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OASuggestedDownloadsItem *downloadItem in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary new];
            jsonObject[@"scope-id"] = downloadItem.scopeId;
            if (downloadItem.limit != -1)
                jsonObject[@"limit"] = [NSNumber numberWithInteger:downloadItem.limit];
            if (downloadItem.searchType && downloadItem.searchType.length != 0)
                jsonObject[@"search-type"] = downloadItem.searchType;
            if (downloadItem.names && downloadItem.names.count != 0)
                jsonObject[@"names"] = downloadItem.names;
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = [NSArray arrayWithArray:jsonArray];
    }
}

- (OASettingsItemWriter *)getWriter
{
    return [self getJsonWriter];
}

@end
