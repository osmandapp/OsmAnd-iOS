//
//  OABaseCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol OACollectionCellDelegate

- (void)onCellSelected:(NSIndexPath *)indexPath;

@end

@interface OABaseCollectionHandler : NSObject

- (instancetype)initWithData:(NSMutableArray<NSMutableArray *> *)data;

- (NSString *)getCellIdentifier;
- (CGSize)getItemSize;
- (UICollectionViewScrollDirection)getScrollDirection;
- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection;

- (NSIndexPath *)getSelectedIndexPath;
- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath;

- (NSInteger)rowsCount:(NSInteger)section;
- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;
- (NSInteger)sectionsCount;
- (void)onRowSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;

@property (nonatomic, weak) id<OACollectionCellDelegate> delegate;

@end
