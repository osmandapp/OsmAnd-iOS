//
//  OAHorizontalCollectionViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAHorizontalCollectionViewCell.h"
#import "OALabelCollectionViewCell.h"
#import "OAColors.h"
#import "OAUtilities.h"

#define kSidePadding 16

@implementation OAHorizontalCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OALabelCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OALabelCollectionViewCell getCellIdentifier]];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    self.contentView.frame = self.bounds;
    [self.contentView layoutIfNeeded];
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
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
    OALabelCollectionViewCell* cell = nil;
    cell = (OALabelCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[OALabelCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    
    cell.titleLabel.text = _dataArray[indexPath.row];
    if (indexPath.row == _selectedIndex)
    {
        cell.backView.backgroundColor = UIColorFromRGB(color_primary_purple);
        cell.titleLabel.textColor = UIColorFromRGB(color_icon_color_night);
        cell.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    }
    else
    {
        cell.backView.backgroundColor = UIColorFromRGB(color_route_button_inactive);
        cell.titleLabel.textColor = UIColorFromRGB(color_primary_purple);
        cell.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    }
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize labelSize = [(NSString*)[_dataArray objectAtIndex:indexPath.row] sizeWithAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold]}];
    CGFloat w = labelSize.width + kSidePadding * 2;
    CGSize itemSize = CGSizeMake(w, 58);
    return itemSize;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndex = indexPath.row;
    if (self.delegate)
        [self.delegate valueChanged:indexPath.row];
    [self.collectionView reloadData];
}

@end
