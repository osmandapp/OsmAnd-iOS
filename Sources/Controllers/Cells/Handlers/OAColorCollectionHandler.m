//
//  OAColorsCollectionHandler.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorCollectionHandler.h"
#import "OAColorsCollectionViewCell.h"
#import "OAGPXAppearanceCollection.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"

#define kWhiteColor 0x44FFFFFF

@implementation OAColorCollectionHandler
{
    NSMutableArray<NSMutableArray<NSString *> *> *_data;
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

    if (self.delegate && ![self.delegate isDefaultColor:indexPath])
    {
        UIAction *editAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_edit")
                                                   image:[UIImage systemImageNamed:@"pencil"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
            [self.delegate onItemEdit:indexPath];
        }];
        editAction.accessibilityLabel = OALocalizedString(@"shared_string_edit_color");
        [menuElements addObject:editAction];
    }

    UIAction *duplicateAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_duplicate")
                                                    image:[UIImage systemImageNamed:@"doc.on.doc"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
                 if (self.delegate)
                     [self.delegate onItemDuplicate:indexPath];
    }];
    duplicateAction.accessibilityLabel = OALocalizedString(@"shared_string_duplicate_color");
    [menuElements addObject:duplicateAction];

    if (self.delegate && ![self.delegate isDefaultColor:indexPath])
    {
        UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [self.delegate onItemDelete:indexPath];
        }];
        deleteAction.accessibilityLabel = OALocalizedString(@"shared_string_delete_color");
        [menuElements addObject:[UIMenu menuWithTitle:@""
                                           image:nil
                                      identifier:nil
                                         options:UIMenuOptionsDisplayInline
                                        children:@[deleteAction]]];
    }

    return [UIMenu menuWithChildren:menuElements];
}

#pragma mark - Data

- (void)addAndSelectHexKey:(NSString *)hexKey collectionView:(UICollectionView *)collectionView
{
    [_data.firstObject addObject:hexKey];
    NSIndexPath *prevSelectedIndexPath = _selectedIndexPath;
    _selectedIndexPath = [NSIndexPath indexPathForRow:[collectionView numberOfItemsInSection:_selectedIndexPath.section] inSection:0];
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[_selectedIndexPath]];
    } completion:^(BOOL finished) {
        [collectionView reloadItemsAtIndexPaths:@[prevSelectedIndexPath, _selectedIndexPath]];
        if (self.delegate)
        {
            [self.delegate onCollectionItemSelected:_selectedIndexPath];
            [self.delegate reloadCollectionData];
        }
    }];
}

- (void)replaceOldColor:(NSIndexPath *)indexPath withNewHexKey:(NSString *)newHexKey collectionView:(UICollectionView *)collectionView
{
    [_data[indexPath.section] replaceObjectAtIndex:indexPath.row withObject:newHexKey];
    if (indexPath == _selectedIndexPath)
        [self onItemSelected:_selectedIndexPath collectionView:collectionView];
    else
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)addDuplicatedHexKey:(NSString *)hexKey toNewIndexPath:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    [_data[indexPath.section] insertObject:hexKey atIndex:indexPath.row];
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        if (self.delegate)
            [self.delegate reloadCollectionData];
    }];
}

- (void)removeColor:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    [_data[indexPath.section] removeObjectAtIndex:indexPath.row];
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        if (indexPath == _selectedIndexPath)
        {
            _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [collectionView reloadItemsAtIndexPaths:@[_selectedIndexPath]];
            if (self.delegate)
                [self.delegate onCollectionItemSelected:_selectedIndexPath];
        }
        else if (indexPath.row < _selectedIndexPath.row)
        {
            _selectedIndexPath = [NSIndexPath indexPathForRow:_selectedIndexPath.row - 1 inSection:_selectedIndexPath.section];
            [collectionView reloadItemsAtIndexPaths:@[_selectedIndexPath]];
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

- (void)generateData:(NSMutableArray<NSMutableArray<NSString *> *> *)data
{
    _data = data;
}

- (NSInteger)itemsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSString *hexKey = _data[indexPath.section][indexPath.row];
    NSInteger color = [OAUtilities colorToNumberFromString:[OAGPXAppearanceCollection getOriginalHexColor:hexKey]];
    OAColorsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[OAColorsCollectionViewCell getCellIdentifier]
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
        if (color == kWhiteColor)
        {
            cell.colorView.layer.borderWidth = 1;
            cell.colorView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
        }
        else
        {
            cell.colorView.layer.borderWidth = 0;
        }

        UIColor *aColor = UIColorFromARGB(color);
        cell.colorView.backgroundColor = aColor;
        cell.chessboardView.image = [UIImage templateImageNamed:@"bg_color_chessboard_pattern"];
        cell.chessboardView.tintColor = UIColorFromRGB(color);

        if (indexPath == _selectedIndexPath)
        {
            cell.backView.layer.borderWidth = 2;
            cell.backView.layer.borderColor = UIColorFromARGB(color_primary_purple_50).CGColor;
        }
        else
        {
            cell.backView.layer.borderWidth = 0;
            cell.backView.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

@end
