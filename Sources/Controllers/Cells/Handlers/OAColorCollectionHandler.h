//
//  OAColorsCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"

@protocol OAColorsCollectionCellDelegate <OACollectionCellDelegate>

- (BOOL)isDefaultColor:(NSIndexPath *)indexPath;
- (void)onItemEdit:(NSIndexPath *)indexPath;
- (void)onItemDuplicate:(NSIndexPath *)indexPath;
- (void)onItemDelete:(NSIndexPath *)indexPath;

@end

@interface OAColorCollectionHandler : OABaseCollectionHandler

@property (nonatomic, weak) id<OAColorsCollectionCellDelegate> delegate;

- (void)addAndSelectColor:(NSInteger)color collectionView:(UICollectionView *)collectionView;
- (void)replaceOldColor:(NSIndexPath *)indexPath withNewColor:(NSInteger)newColor collectionView:(UICollectionView *)collectionView;
- (void)duplicateColor:(NSIndexPath *)indexPath isDefaultColor:(BOOL)isDefault collectionView:(UICollectionView *)collectionView;
- (void)removeColor:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;

@end
