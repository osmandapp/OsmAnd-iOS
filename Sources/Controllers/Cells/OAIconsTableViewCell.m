//
//  OAIconsTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconsTableViewCell.h"
#import "OAIconsCollectionViewCell.h"
#import "OAColors.h"

@implementation OAIconsTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAIconsTableViewCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAIconsCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAIconsCollectionViewCell getCellIdentifier]];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    self.contentView.frame = self.bounds;
    [self.contentView layoutIfNeeded];
    self.collectionViewHeight.constant = self.collectionView.contentSize.height;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAIconsCollectionViewCell* cell = nil;
    cell = (OAIconsCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[OAIconsCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    UIImage *img = nil;
    NSString *imgName = _dataArray[indexPath.row];
    img = [UIImage imageNamed:imgName];
    cell.iconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.iconImageView.tintColor = UIColorFromRGB(color_icon_inactive);
    
    if (indexPath.row == _currentIcon)
    {
        cell.backView.layer.borderWidth = 2;
        cell.backView.layer.borderColor = UIColorFromRGB(_currentColor).CGColor;
        cell.iconImageView.tintColor = UIColorFromRGB(_currentColor);
    }
    else
    {
        cell.backView.layer.borderWidth = 0;
        cell.backView.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(48.0, 48.0);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate iconChanged:indexPath.row];
}

@end
