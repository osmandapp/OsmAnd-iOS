//
//  OASeveralViewsTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASeveralViewsTableViewCell.h"
#import "OAViewsCollectionViewCell.h"
#import "OAColors.h"

@implementation OASeveralViewsTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"OAViewsCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"OAViewsCollectionViewCell"];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
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
    static NSString* const identifierCell = @"OAViewsCollectionViewCell";
    OAViewsCollectionViewCell* cell = nil;
    cell = (OAViewsCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifierCell forIndexPath:indexPath];
    UIImage *img = _dataArray[indexPath.row];
    cell.iconImageView.image = img;
    cell.iconImageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    if (indexPath.row == 0)
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
    return CGSizeMake(164.0, 104.0);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate mapIconChanged:indexPath.row];
}

@end
