//
//  OASeveralViewsTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OALocationIconsTableViewCell.h"
#import "OAIconBackgroundCollectionViewCell.h"
#import "OAColors.h"

@implementation OALocationIconsTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAIconBackgroundCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAIconBackgroundCollectionViewCell getCellIdentifier]];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    self.contentView.frame = self.bounds;
    [self.contentView layoutIfNeeded];
    self.collectionViewHeight.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAIconBackgroundCollectionViewCell* cell = nil;
    cell = (OAIconBackgroundCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[OAIconBackgroundCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    UIImage *img = _dataArray[indexPath.row];
    cell.iconImageView.image = img;
    if (_locationType == EOALocationTypeMoving)
        cell.iconImageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    else
        cell.iconImageView.transform = CGAffineTransformIdentity;
    if (indexPath.row == _selectedIndex)
    {
        cell.backView.layer.borderWidth = 2;
        cell.backView.layer.borderColor = UIColorFromRGB(_currentColor).CGColor;
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
    return CGSizeMake(self.collectionView.frame.size.width / 2 - 16.0, 108.0);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndex = indexPath.row;
    if (self.delegate)
        [self.delegate mapIconChanged:indexPath.row type:_locationType];
}

@end
