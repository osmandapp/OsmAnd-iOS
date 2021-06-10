//
//  OAImagesTableViewCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 09.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAImagesTableViewCell.h"
#import "OAImagesCollectionViewCell.h"

@implementation OAImagesTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAImagesCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAImagesCollectionViewCell getCellIdentifier]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.collectionView.frame = CGRectMake(-OAUtilities.getLeftMargin, 0, self.collectionView.frame.size.width, self.collectionView.frame.size.height);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

#pragma mark UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _images.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAImagesCollectionViewCell* cell = nil;
    cell = (OAImagesCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[OAImagesCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    cell.imageView.image = _images[indexPath.row];
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(_collectionViewWidth.constant, _collectionViewHeight.constant);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.1;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.collectionView.frame = CGRectMake(-OAUtilities.getLeftMargin, 0, self.collectionView.frame.size.width, self.collectionView.frame.size.height);
}

@end

