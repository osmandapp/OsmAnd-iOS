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

- (instancetype)initWithData:(NSMutableArray<NSMutableArray *> *)data
{
    self = [super init];
    if (self)
    {
        _scrollDirection = UICollectionViewScrollDirectionHorizontal;
        [self generateData:data];
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

- (UIMenu *)getMenuForItem:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    return nil;
}

#pragma mark - Data

- (NSIndexPath *)getSelectedIndexPath
{
    return nil;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
}

- (void)generateData:(NSMutableArray<NSMutableArray *> *)data
{
}

- (NSInteger)itemsCount:(NSInteger)section
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

- (void)onItemSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSIndexPath *prevSelectedColorIndex = [self getSelectedIndexPath];
    [self setSelectedIndexPath:indexPath];
    [collectionView reloadItemsAtIndexPaths:prevSelectedColorIndex ? @[prevSelectedColorIndex, indexPath] : @[indexPath]];
    if (self.delegate)
        [self.delegate onCollectionItemSelected:indexPath];
}

@end
