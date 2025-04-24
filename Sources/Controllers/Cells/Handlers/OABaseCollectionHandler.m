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
    UICollectionView *_collectionView;
}

#pragma mark - Initialization

- (instancetype)initWithData:(NSArray<NSArray *> *)data collectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self)
    {
        _scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = collectionView;
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

- (CGFloat)getSpacing
{
    return 9;
}

- (CGSize)calculateItemSizeForIndexPath:(NSIndexPath *)indexPath
{
    return [self getItemSize];
}

- (UICollectionView *)getCollectionView
{
    return _collectionView;
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
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

- (NSIndexPath *)getDefaultIndexPath
{
    return nil;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
}

- (id)getSelectedItem
{
    return nil;
}

- (void)generateData:(NSArray<NSArray *> *)data
{
}

- (void)insertItem:(id)newItem atIndexPath:(NSIndexPath *)indexPath
{
}

- (void)replaceItem:(id)newItem atIndexPath:(NSIndexPath *)indexPath
{
}

- (void)removeItem:(NSIndexPath *)indexPath
{
}

- (void)removeItems:(NSArray<NSIndexPath *> *)indexPaths
{
}

- (NSInteger)itemsCount:(NSInteger)section
{
    return 0;
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath
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
    id selectedItem = [self getSelectedItem];
    [collectionView reloadData];
    if (self.delegate)
        [self.delegate onCollectionItemSelected:indexPath selectedItem:selectedItem collectionView:collectionView shouldDismiss:YES];
}

@end
