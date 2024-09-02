//
//  OAColorsCollectionHandler.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorCollectionHandler.h"
#import "OAColorsCollectionViewCell.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kWhiteColor 0x44FFFFFF

@interface OAColorCollectionHandler ()

@property(nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation OAColorCollectionHandler
{
    NSMutableArray<NSMutableArray<OAColorItem *> *> *_data;
}

@synthesize delegate;

#pragma mark - Base UI

- (NSString *)getCellIdentifier
{
    return OAColorsCollectionViewCell.reuseIdentifier;
}

- (UIMenu *)getMenuForItem:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    BOOL isDefaultColor = _data[indexPath.section][indexPath.row].isDefault;
    if (self.delegate && !isDefaultColor)
    {
        UIAction *editAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_edit")
                                                   image:[UIImage systemImageNamed:@"pencil"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf.delegate onContextMenuItemEdit:indexPath];
        }];
        editAction.accessibilityLabel = OALocalizedString(@"shared_string_edit_color");
        [menuElements addObject:editAction];
    }

    UIAction *duplicateAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_duplicate")
                                                    image:[UIImage systemImageNamed:@"doc.on.doc"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
        if (weakSelf.delegate)
            [weakSelf.delegate duplicateItemFromContextMenu:indexPath];
    }];
    duplicateAction.accessibilityLabel = OALocalizedString(@"shared_string_duplicate_color");
    [menuElements addObject:duplicateAction];

    if (self.delegate && !isDefaultColor)
    {
        UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf.delegate deleteItemFromContextMenu:indexPath];
        }];
        deleteAction.accessibilityLabel = OALocalizedString(@"shared_string_delete_color");
        deleteAction.attributes = UIMenuElementAttributesDestructive;
        [menuElements addObject:[UIMenu menuWithTitle:@""
                                           image:nil
                                      identifier:nil
                                         options:UIMenuOptionsDisplayInline
                                        children:@[deleteAction]]];
    }

    return isDefaultColor ? [UIMenu menuWithTitle:OALocalizedString(@"access_default_color") children:menuElements] : [UIMenu menuWithChildren:menuElements];
}

#pragma mark - Data

- (void)addAndSelectColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    NSIndexPath *prevSelectedIndexPath = indexPath.row <= _selectedIndexPath.row
        ? [NSIndexPath indexPathForRow:_selectedIndexPath.row + 1 inSection:_selectedIndexPath.section]
        : _selectedIndexPath;
    _selectedIndexPath = indexPath;
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[weakSelf.selectedIndexPath]];
        [weakSelf insertItem:newItem atIndexPath:indexPath];
    } completion:^(BOOL finished) {
        [collectionView reloadItemsAtIndexPaths:@[prevSelectedIndexPath, weakSelf.selectedIndexPath]];
        if (weakSelf.delegate)
        {
            [weakSelf.delegate onCollectionItemSelected:weakSelf.selectedIndexPath];
            [weakSelf.delegate reloadCollectionData];
        }
        if (![collectionView.indexPathsForVisibleItems containsObject:weakSelf.selectedIndexPath])
        {
            [collectionView scrollToItemAtIndexPath:weakSelf.selectedIndexPath
                                   atScrollPosition:[weakSelf getScrollDirection] == UICollectionViewScrollDirectionHorizontal
                                                        ? UICollectionViewScrollPositionCenteredHorizontally
                                                        : UICollectionViewScrollPositionCenteredVertically
                                           animated:YES];
        }
    }];
}

- (void)replaceOldColor:(NSIndexPath *)indexPath
{
    UICollectionView *collectionView = [self getCollectionView];
    if (collectionView)
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];

    if (self.delegate)
    {
        if (indexPath == _selectedIndexPath)
            [self.delegate onCollectionItemSelected:indexPath];
        else
            [self.delegate reloadCollectionData];
    }
}

- (void)addColor:(NSIndexPath *)indexPath newItem:(OAColorItem *)newItem
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
        [weakSelf insertItem:newItem atIndexPath:indexPath];
    } completion:^(BOOL finished) {
        if (indexPath.row <= weakSelf.selectedIndexPath.row)
        {
            NSIndexPath *prevSelectedIndexPath = weakSelf.selectedIndexPath;
            weakSelf.selectedIndexPath = [NSIndexPath indexPathForRow:weakSelf.selectedIndexPath.row + 1 inSection:weakSelf.selectedIndexPath.section];
            [collectionView reloadItemsAtIndexPaths:@[prevSelectedIndexPath, weakSelf.selectedIndexPath]];
        }
        if (weakSelf.delegate)
            [weakSelf.delegate reloadCollectionData];

        if (![collectionView.indexPathsForVisibleItems containsObject:indexPath])
        {
            [collectionView scrollToItemAtIndexPath:indexPath
                                   atScrollPosition:[weakSelf getScrollDirection] == UICollectionViewScrollDirectionHorizontal
                                                        ? UICollectionViewScrollPositionCenteredHorizontally
                                                        : UICollectionViewScrollPositionCenteredVertically
                                           animated:YES];
        }
    }];
}

- (void)removeColor:(NSIndexPath *)indexPath
{
    UICollectionView *collectionView = [self getCollectionView];
    if (!collectionView)
        return;

    __weak __typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
        [weakSelf removeItem:indexPath];
    } completion:^(BOOL finished) {
        if (indexPath == weakSelf.selectedIndexPath)
        {
            weakSelf.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [collectionView reloadItemsAtIndexPaths:@[weakSelf.selectedIndexPath]];
            if (weakSelf.delegate)
                [weakSelf.delegate onCollectionItemSelected:weakSelf.selectedIndexPath];

            if (![collectionView.indexPathsForVisibleItems containsObject:weakSelf.selectedIndexPath])
            {
                [collectionView scrollToItemAtIndexPath:weakSelf.selectedIndexPath
                                       atScrollPosition:[weakSelf getScrollDirection] == UICollectionViewScrollDirectionHorizontal
                                                            ? UICollectionViewScrollPositionCenteredHorizontally
                                                            : UICollectionViewScrollPositionCenteredVertically
                                               animated:YES];
            }
        }
        else if (indexPath.row < weakSelf.selectedIndexPath.row)
        {
            weakSelf.selectedIndexPath = [NSIndexPath indexPathForRow:weakSelf.selectedIndexPath.row - 1 inSection:weakSelf.selectedIndexPath.section];
        }
    }];
}

- (NSIndexPath *)getSelectedIndexPath
{
    return _selectedIndexPath;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    _selectedIndexPath = selectedIndexPath;
}

- (void)generateData:(NSArray<NSArray<OAColorItem *> *> *)data
{
    NSMutableArray<NSMutableArray<OAColorItem *> *> *newData = [NSMutableArray array];
    for (NSArray *items in data)
    {
        [newData addObject:[NSMutableArray arrayWithArray:items]];
    }
    _data = newData;
}

- (void)insertItem:(id)newItem atIndexPath:(NSIndexPath *)indexPath
{
    if (_data.count > indexPath.section && (indexPath.row == 0 || _data[indexPath.section].count > indexPath.row - 1))
        [_data[indexPath.section] insertObject:newItem atIndex:indexPath.row];
}

- (void)removeItem:(NSIndexPath *)indexPath
{
    if (_data.count > indexPath.section && _data[indexPath.section].count > indexPath.row)
        [_data[indexPath.section] removeObjectAtIndex:indexPath.row];
}

- (NSInteger)itemsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath
{
    OAColorsCollectionViewCell *cell = [[self getCollectionView] dequeueReusableCellWithReuseIdentifier:[self getCellIdentifier] forIndexPath:indexPath];
    NSInteger colorValue = _data[indexPath.section][indexPath.row].value;
    if (colorValue == kWhiteColor)
    {
        cell.colorView.layer.borderWidth = 1;
        cell.colorView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    }
    else
    {
        cell.colorView.layer.borderWidth = 0;
    }

    UIColor *color = UIColorFromARGB(colorValue);
    cell.colorView.backgroundColor = color;
    cell.backgroundImageView.image = [UIImage templateImageNamed:@"bg_color_chessboard_pattern"];
    cell.backgroundImageView.tintColor = UIColorFromRGB(colorValue);

    if (indexPath == _selectedIndexPath)
    {
        cell.selectionView.layer.borderWidth = 2;
        cell.selectionView.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
    }
    else
    {
        cell.selectionView.layer.borderWidth = 0;
        cell.selectionView.layer.borderColor = UIColor.clearColor.CGColor;
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

@end
