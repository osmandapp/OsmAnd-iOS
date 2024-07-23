//
//  OADownloadsItem.m
//  OsmAnd Maps
//
//  Created by Paul on 24.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADownloadsItem.h"
#import "OAWorldRegion.h"
#import "OACustomRegion.h"
#import "OACustomPlugin.h"
#import "Localization.h"

#define APPROXIMATE_DOWNLOAD_ITEM_SIZE_BYTES 2048

@implementation OADownloadsItem

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeDownloads;
}

- (NSString *)name
{
    return @"downloads";
}

- (void)readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    if (!json[@"items"])
        return;
    
    if (!_items)
        _items = [NSArray array];
    
    NSArray *jsonArr = json[@"items"];
    _items = [_items arrayByAddingObjectsFromArray:[OACustomPlugin collectRegionsFromJson:jsonArr]];
}

- (void) writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAWorldRegion *region in self.items)
        {
            [jsonArray addObject:((OACustomRegion *) region).toJson];
        }
        json[@"items"] = jsonArray;
    }
}

- (long)getEstimatedSize
{
    return APPROXIMATE_DOWNLOAD_ITEM_SIZE_BYTES;
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"welmode_download_maps");
}

- (OASettingsItemWriter *)getWriter
{
    return [self getJsonWriter];
}

@end
