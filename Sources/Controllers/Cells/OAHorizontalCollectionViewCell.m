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

@implementation OAHorizontalCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"OALabelCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"OALabelCollectionViewCell"];
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
    static NSString* const identifierCell = @"OALabelCollectionViewCell";
    OALabelCollectionViewCell* cell = nil;
    cell = (OALabelCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifierCell forIndexPath:indexPath];
    
    cell.titleLabel.text = _dataArray[indexPath.row];
    
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(70.0, 40.0);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate iconChanged:indexPath.row];
}

@end
