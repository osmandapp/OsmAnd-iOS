//
//  OACollectionSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

@interface OACollectionSettingsItem<ObjectType> : OASettingsItem

@property (nonatomic, readonly) NSArray<ObjectType> *items;
@property (nonatomic, readonly) NSArray<ObjectType> *appliedItems;
@property (nonatomic, readonly) NSArray<ObjectType> *duplicateItems;
@property (nonatomic, readonly) NSArray<ObjectType> *existingItems;

- (instancetype) initWithItems:(NSArray<ObjectType> *)items;
- (instancetype) initWithItems:(NSArray<ObjectType> *)items baseItem:(OACollectionSettingsItem<ObjectType> *)baseItem;
- (NSArray<ObjectType> *) processDuplicateItems;
- (NSArray<ObjectType> *) getNewItems;
- (BOOL) isDuplicate:(ObjectType)item;
- (ObjectType) renameItem:(ObjectType)item;
- (BOOL) shouldShowDuplicates;

@end
