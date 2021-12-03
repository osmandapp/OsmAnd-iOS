//
//  OAColorsTableViewCell.m
//  OsmAnd
//
//  Created by igor on 06.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAColorsTableViewCell.h"
#import "OAColorsCollectionViewCell.h"
#import "OAColors.h"

#define kWhiteColor 0x44FFFFFF

@implementation OAColorsTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAColorsCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAColorsCollectionViewCell getCellIdentifier]];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    // First layout the collectionView
    self.contentView.frame = self.bounds;
    [self.contentView layoutIfNeeded];
    self.collectionViewHeight.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (CGFloat)getAlphaForColor:(NSInteger)color
{
    NSString *colorKey = [NSString stringWithFormat:@"%li", color];
    if (self.translucentDataDict && [self.translucentDataDict.allKeys containsObject:colorKey])
        return [self.translucentDataDict[colorKey] floatValue];

    return 1.;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAColorsCollectionViewCell *cell =
            [collectionView dequeueReusableCellWithReuseIdentifier:[OAColorsCollectionViewCell getCellIdentifier]
                                                      forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsCollectionViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = nib[0];
    }
    if (cell)
    {
        NSInteger color = [_dataArray[indexPath.row] integerValue];
        if (color == kWhiteColor)
        {
            cell.colorView.layer.borderWidth = 1;
            cell.colorView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
        }
        else
        {
            cell.colorView.layer.borderWidth = 0;
        }

        UIColor *backgroundColor = UIColorFromRGB(color);
        cell.colorView.backgroundColor = backgroundColor;

        UIImage *image = [UIImage templateImageNamed:@"bg_color_chessboard_pattern"];
        cell.chessboardView.image = image;
        cell.chessboardView.tintColor = backgroundColor;
        [cell setChessboardAlpha:[self getAlphaForColor:color]];

        if (indexPath.row == _currentColor)
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(48.0, 48.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate colorChanged:indexPath.row];
}

- (void)showLabels:(BOOL)showLabels;
{
    self.titleLabel.hidden = !showLabels;
    self.valueLabel.hidden = !showLabels;
}

- (void)updateConstraints
{
    BOOL hasLabels = !self.titleLabel.hidden && !self.valueLabel.hidden;

    self.collectionViewLabelsTopConstraint.active = hasLabels;
    self.collectionViewNoLabelsTopConstraint.active = !hasLabels;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasLabels = !self.titleLabel.hidden && !self.valueLabel.hidden;

        res = res || self.collectionViewLabelsTopConstraint.active != hasLabels;
        res = res || self.collectionViewNoLabelsTopConstraint.active != !hasLabels;
    }
    return res;
}

@end
