//
//  OAHistorySettingsItem.h
//  OsmAnd
//
//  Created by Max Kojin on 25/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"

NS_ASSUME_NONNULL_BEGIN

@class OAHistoryItem;

@interface OAHistorySettingsItem : OACollectionSettingsItem<OAHistoryItem *>

@property (nonatomic) NSMutableArray<OAHistoryItem *> *items;
@property (nonatomic) NSMutableArray<OAHistoryItem *> *appliedItems;
@property (nonatomic) NSMutableArray<OAHistoryItem *> *existingItems;

- (instancetype) initWithItems:(NSArray<OAHistoryItem *> *)items;
- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
