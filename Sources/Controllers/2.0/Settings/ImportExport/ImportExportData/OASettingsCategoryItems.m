//
//  OASettingsCategoryItems.m
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASettingsCategoryItems.h"
#import "OAExportSettingsType.h"

@implementation OASettingsCategoryItems
{
    NSDictionary<OAExportSettingsType *, NSArray *> *_itemsMap;
}

- (instancetype) initWithItemsMap:(NSDictionary<OAExportSettingsType *, NSArray *> *)itemsMap
{
    self = [super init];
    if (self) {
        _itemsMap = itemsMap;
    }
    return self;
}

- (NSArray<OAExportSettingsType *> *) getTypes
{
    return _itemsMap.allKeys;
}

- (NSArray *) getItemsForType:(OAExportSettingsType *)type
{
    return _itemsMap[type];
}

@end
