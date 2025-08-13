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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kWhiteColor 0x44FFFFFF

@implementation OAColorsTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAColorsCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAColorsCollectionViewCell getCellIdentifier]];
    
    if ([self isDirectionRTL])
    {
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.valueLabel.textAlignment = NSTextAlignmentLeft;
    }
    else
    {
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.valueLabel.textAlignment = NSTextAlignmentRight;
    }
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

        UIColor *aColor = UIColorFromRGB(color);
        cell.colorView.backgroundColor = aColor;
        cell.backgroundImageView.image = [UIImage templateImageNamed:@"bg_color_chessboard_pattern"];
        cell.backgroundImageView.tintColor = UIColorFromRGB(color);

        if (indexPath.row == _currentColor)
        {
            cell.selectionView.layer.borderWidth = 2;
            cell.selectionView.layer.borderColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary].CGColor;
        }
        else
        {
            cell.selectionView.layer.borderWidth = 0;
            cell.selectionView.layer.borderColor = [UIColor clearColor].CGColor;
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
