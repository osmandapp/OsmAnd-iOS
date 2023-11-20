//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"

@class OAColorItem;

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath;
- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath;
- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler

@property (nonatomic, weak) id<OAColorsCollectionCellDelegate> delegate;

- (void)addColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem;
- (void)replaceOldColor:(NSIndexPath *)indexPath;
- (void)removeColor:(NSIndexPath *)indexPath;

@end
