//
//  OABaseCollectionHandler.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCollectionHandler.h"

@implementation OABaseCollectionHandler
{
    UICollectionViewScrollDirection _scrollDirection;
}

#pragma mark - Initialization

- (instancetype)initWithData:(NSArray<NSArray *> *)data selectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    self = [super init];
    if (self)
    {
        _scrollDirection = UICollectionViewScrollDirectionHorizontal;
        [self generateData:data selectedIndexPath:selectedIndexPath];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getCellIdentifier
{
    return nil;
}

- (CGSize)getItemSize
{
    return CGSizeMake(48., 48.);
}

- (UICollectionViewScrollDirection)getScrollDirection
{
    return _scrollDirection;
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
}

#pragma mark - Data

- (void)generateData:(NSArray<NSArray *> *)data selectedIndexPath:(NSIndexPath *)selectedIndexPath
{
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return 0;
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    return nil;
}

- (NSInteger)sectionsCount
{
    return 0;
}

- (void)onRowSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    if (self.delegate)
        [self.delegate onCellSelected:indexPath];
}

@end
