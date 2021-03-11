//
//  OAPoiTableViewCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPoiTableViewCell.h"
#import "OAPoiCollectionViewCell.h"
#import "OAColors.h"

@implementation OAPoiTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"OAPoiCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"OAPoiCollectionViewCell"];
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
    static NSString* const identifierCell = @"OAPoiCollectionViewCell";
    OAPoiCollectionViewCell* cell = nil;
    cell = (OAPoiCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifierCell forIndexPath:indexPath];
    UIImage *img = nil;
    NSString *imgName = [NSString stringWithFormat:@"mm_%@", _dataArray[indexPath.row]];
    img = [OAUtilities applyScaleFactorToImage:[UIImage imageNamed:[OAUtilities drawablePath:imgName]]];
    
    cell.iconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.iconImageView.tintColor = UIColorFromRGB(color_icon_inactive);
    
    if (indexPath.row == _currentIcon)
    {
        cell.backView.layer.borderWidth = 2;
        cell.backView.layer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
        cell.iconImageView.tintColor = UIColor.whiteColor;
        cell.iconView.backgroundColor = UIColorFromRGB(_currentColor);
    }
    else
    {
        
        cell.backView.layer.borderWidth = 0;
        cell.backView.layer.borderColor = [UIColor clearColor].CGColor;
        cell.iconView.backgroundColor = UIColorFromARGB(color_primary_purple_10);
        cell.iconImageView.tintColor = UIColorFromRGB(color_primary_purple);
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
        [self.delegate poiChanged:indexPath.row];
}

@end
