//
//  OAItemExporter.m
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAItemExporter.h"
#import "OrderedDictionary.h"
#import "OASettingsItem.h"
#import "OAAbstractWriter.h"

@implementation OAItemExporter
{
    NSMutableArray<OASettingsItem *> *_items;
    MutableOrderedDictionary<NSString *, NSString *> *_additionalParams;
    BOOL _cancelled;
}

- (instancetype) initWithListener:(id<OAExportProgressListener>)listener
{
    self = [super init];
    if (self) {
        _progressListener = listener;
        _items = [NSMutableArray array];
        _additionalParams = [MutableOrderedDictionary dictionary];
    }
    return self;
}

- (void) addSettingsItem:(OASettingsItem *)item
{
    [_items addObject:item];
}

- (NSArray<OASettingsItem *> *)getItems
{
    return _items;
}

- (BOOL) isCancelled
{
    return _cancelled;
}

- (void) cancel
{
    _cancelled = YES;
}

- (void) addAdditionalParam:(NSString *)key value:(NSString *)value
{
    if (!key || !value)
        return;
    _additionalParams[key] = value;
}

- (void) doExport
{
    // Override
}

- (void) writeItems:(OAAbstractWriter *)writer
{
    for (OASettingsItem *item in self.getItems)
    {
        [writer write:item];
        if ([self isCancelled])
            break;
    }
}

- (NSDictionary *) createItemsJson
{
    MutableOrderedDictionary *json = [MutableOrderedDictionary new];
    json[@"version"] = @(kVersion);
    [_additionalParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        json[key] = obj;
    }];
    NSMutableArray *items = [NSMutableArray new];
    for (OASettingsItem *item in _items)
    {
        MutableOrderedDictionary *json = [MutableOrderedDictionary new];
        [item writeToJson:json];
        [items addObject:json];
    }
    json[@"items"] = items;
    
    return json;
}

@end
