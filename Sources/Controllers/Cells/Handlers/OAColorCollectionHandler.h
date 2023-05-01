//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (BOOL)isDefaultColor:(NSString *)hexKey;
- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath;
- (void)onContextMenuItemDuplicate:(NSIndexPath *)indexPath;
- (void)onContextMenuItemDelete:(NSIndexPath *)indexPath;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler

@property (nonatomic, weak) id<OAColorsCollectionCellDelegate> delegate;

- (void)addAndSelectIndexPath:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;
- (void)replaceOldColor:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;
- (void)addDuplicatedHexKey:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;
- (void)removeColor:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;

@end
