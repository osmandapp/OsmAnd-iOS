//
//  OAColorsCollectionHandler.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorsCollectionHandler.h"
#import "OAColorsCollectionViewCell.h"
#import "OAColors.h"

#define kWhiteColor 0x44FFFFFF

@implementation OAColorsCollectionHandler
{
    NSArray<NSArray<NSNumber *> *> *_data;
    NSIndexPath *_selectedIndexPath;
}

#pragma mark - Base UI

- (NSString *)getCellIdentifier
{
    return [OAColorsCollectionViewCell getCellIdentifier];
}

#pragma mark - Data

- (void)generateData:(NSArray<NSArray *> *)data selectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    _data = data;
    _selectedIndexPath = selectedIndexPath;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSInteger color = _data[indexPath.section][indexPath.row].integerValue;
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

- (void)onRowSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    NSIndexPath *prevSelectedColorIndex = _selectedIndexPath;
    _selectedIndexPath = indexPath;
    [collectionView reloadItemsAtIndexPaths:@[prevSelectedColorIndex, indexPath]];
    [super onRowSelected:indexPath collectionView:collectionView];
}

@end
