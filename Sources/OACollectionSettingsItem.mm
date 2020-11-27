//
//  OACollectionSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

@interface OACollectionSettingsItem()

@property (nonatomic) NSMutableArray<id> *items;
@property (nonatomic) NSMutableArray<id> *appliedItems;
@property (nonatomic) NSMutableArray<id> *duplicateItems;
@property (nonatomic) NSMutableArray<id> *existingItems;

@end

@implementation OACollectionSettingsItem

- (void) initialization
{
    [super initialization];
    
    self.items = [NSMutableArray array];
    self.appliedItems = [NSMutableArray array];
    self.duplicateItems = [NSMutableArray array];
}

- (instancetype) initWithItems:(NSArray<id> *)items
{
    self = [super init];
    if (self)
        _items = items.mutableCopy;
    return self;
}

- (instancetype) initWithItems:(NSArray<id> *)items baseItem:(OACollectionSettingsItem<id> *)baseItem
{
    self = [super initWithBaseItem:baseItem];
    if (self)
        _items = items.mutableCopy;
    
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeUnknown;
}

- (NSArray*) processDuplicateItems
{
    if (_items.count > 0)
    {
        for (id item in _items)
            if ([self isDuplicate:item])
                [_duplicateItems addObject:item];
    }
    return _duplicateItems;
}

- (NSArray<id> *) getNewItems
{
    NSMutableArray<id> *res = [NSMutableArray arrayWithArray:_items];
    [res removeObjectsInArray:_duplicateItems];
    return res;
}

- (BOOL) isDuplicate:(id)item
{
    return [self.existingItems containsObject:item];
}

- (id) renameItem:(id)item
{
    return nil;
}

- (BOOL)shouldShowDuplicates
{
    return YES;
}

@end
