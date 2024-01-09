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

@implementation OAColorCollectionHandler
{
    NSMutableArray<NSMutableArray<OAColorItem *> *> *_data;
    NSIndexPath *_selectedIndexPath;
}

@synthesize delegate;

#pragma mark - Base UI

- (NSString *)getCellIdentifier
{
    return [OAColorsCollectionViewCell getCellIdentifier];
}

- (UIMenu *)getMenuForItem:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];

    BOOL isDefaultColor = _data[indexPath.section][indexPath.row].isDefault;
    if (self.delegate && !isDefaultColor)
    {
        UIAction *editAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_edit")
                                                   image:[UIImage systemImageNamed:@"pencil"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
            [self.delegate onContextMenuItemEdit:indexPath];
        }];
        editAction.accessibilityLabel = OALocalizedString(@"shared_string_edit_color");
        [menuElements addObject:editAction];
    }

    UIAction *duplicateAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_duplicate")
                                                    image:[UIImage systemImageNamed:@"doc.on.doc"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
                 if (self.delegate)
                     [self.delegate duplicateItemFromContextMenu:indexPath];
    }];
    duplicateAction.accessibilityLabel = OALocalizedString(@"shared_string_duplicate_color");
    [menuElements addObject:duplicateAction];

    if (self.delegate && !isDefaultColor)
    {
        UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [self.delegate deleteItemFromContextMenu:indexPath];
        }];
        deleteAction.accessibilityLabel = OALocalizedString(@"shared_string_delete_color");
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

    NSIndexPath *prevSelectedIndexPath = indexPath.row <= _selectedIndexPath.row
        ? [NSIndexPath indexPathForRow:_selectedIndexPath.row + 1 inSection:_selectedIndexPath.section]
        : _selectedIndexPath;
    _selectedIndexPath = indexPath;
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[_selectedIndexPath]];
        [self addItem:indexPath newItem:newItem];
    } completion:^(BOOL finished) {
        [collectionView reloadItemsAtIndexPaths:@[prevSelectedIndexPath, _selectedIndexPath]];
        if (self.delegate)
        {
            [self.delegate onCollectionItemSelected:_selectedIndexPath];
            [self.delegate reloadCollectionData];
        }
        if (![collectionView.indexPathsForVisibleItems containsObject:_selectedIndexPath])
        {
            [collectionView scrollToItemAtIndexPath:_selectedIndexPath
                                   atScrollPosition:[self getScrollDirection] == UICollectionViewScrollDirectionHorizontal
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

    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
        [self addItem:indexPath newItem:newItem];
    } completion:^(BOOL finished) {
        if (indexPath.row <= _selectedIndexPath.row)
        {
            NSIndexPath *prevSelectedIndexPath = _selectedIndexPath;
            _selectedIndexPath = [NSIndexPath indexPathForRow:_selectedIndexPath.row + 1 inSection:_selectedIndexPath.section];
            [collectionView reloadItemsAtIndexPaths:@[prevSelectedIndexPath, _selectedIndexPath]];
        }
        if (self.delegate)
            [self.delegate reloadCollectionData];

        if (![collectionView.indexPathsForVisibleItems containsObject:indexPath])
        {
            [collectionView scrollToItemAtIndexPath:indexPath
                                   atScrollPosition:[self getScrollDirection] == UICollectionViewScrollDirectionHorizontal
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

    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
        [self removeItem:indexPath];
    } completion:^(BOOL finished) {
        if (indexPath == _selectedIndexPath)
        {
            _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [collectionView reloadItemsAtIndexPaths:@[_selectedIndexPath]];
            if (self.delegate)
                [self.delegate onCollectionItemSelected:_selectedIndexPath];

            if (![collectionView.indexPathsForVisibleItems containsObject:_selectedIndexPath])
            {
                [collectionView scrollToItemAtIndexPath:_selectedIndexPath
                                       atScrollPosition:[self getScrollDirection] == UICollectionViewScrollDirectionHorizontal
                                                            ? UICollectionViewScrollPositionCenteredHorizontally
                                                            : UICollectionViewScrollPositionCenteredVertically
                                               animated:YES];
            }
        }
        else if (indexPath.row < _selectedIndexPath.row)
        {
            _selectedIndexPath = [NSIndexPath indexPathForRow:_selectedIndexPath.row - 1 inSection:_selectedIndexPath.section];
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

- (void)addItem:(NSIndexPath *)indexPath newItem:(id)newItem
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
    NSInteger colorValue = _data[indexPath.section][indexPath.row].value;
    OAColorsCollectionViewCell *cell = [[self getCollectionView] dequeueReusableCellWithReuseIdentifier:[OAColorsCollectionViewCell getCellIdentifier]
                                                                                           forIndexPath:indexPath];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsCollectionViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = nib[0];
    }
    if (cell)
    {
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
        cell.chessboardView.image = [UIImage templateImageNamed:@"bg_color_chessboard_pattern"];
        cell.chessboardView.tintColor = UIColorFromRGB(colorValue);

        if (indexPath == _selectedIndexPath)
        {
            cell.backView.layer.borderWidth = 2;
            cell.backView.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
        }
        else
        {
            cell.backView.layer.borderWidth = 0;
            cell.backView.layer.borderColor = UIColor.clearColor.CGColor;
        }
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

@end
