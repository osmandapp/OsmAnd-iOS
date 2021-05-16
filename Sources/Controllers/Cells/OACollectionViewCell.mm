//
//  OACollectionViewCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollectionViewCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OADestinationCollectionViewCell.h"

#define defaultCellHeight 60.0
#define titleTextWidthDelta 50.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

@interface OACollectionViewCell() <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation OACollectionViewCell
{
    NSArray *_data;
}

+ (NSString *) getCellIdentifier
{
    return @"OACollectionViewCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerNib:[UINib nibWithNibName:[OADestinationCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OADestinationCollectionViewCell getCellIdentifier]];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 8.;
    layout.minimumLineSpacing = 8.;
    layout.sectionInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    [_collectionView setCollectionViewLayout:layout];
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    
    _data = [NSArray new];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) setData:(NSArray *)data
{
    _data = data;
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(163.0, 60.0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[OADestinationCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADestinationCollectionViewCell getCellIdentifier] owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OADestinationCollectionViewCell.class])
    {
        OADestinationCollectionViewCell *destCell = (OADestinationCollectionViewCell *) cell;
        destCell.titleLabel.text = item[@"title"];
        destCell.descrLabel.text = item[@"descr"];
        UIColor *tint = item[@"color"];
        if (!tint)
        {
            destCell.imageView.image = [UIImage imageNamed:item[@"img"]];
        }
        else
        {
            destCell.imageView.tintColor = tint;
            destCell.imageView.image = [UIImage templateImageNamed:item[@"img"]];
        }
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (_delegate)
    {
        [_delegate onItemSelected:item[@"key"] point:item[@"point"]];
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    OADestinationCollectionViewCell *cell = (OADestinationCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
    
    [UIView animateWithDuration:.2 animations:^{
        cell.titleLabel.textColor = UIColor.whiteColor;
        cell.descrLabel.textColor = UIColor.whiteColor;
        cell.backgroundColor = UIColorFromRGB(color_primary_purple);
        cell.imageView.tintColor = UIColor.whiteColor;
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    OADestinationCollectionViewCell *cell = (OADestinationCollectionViewCell *) [collectionView cellForItemAtIndexPath:indexPath];
    NSDictionary *item = _data[indexPath.row];
    [UIView animateWithDuration:.2 animations:^{
        cell.titleLabel.textColor = UIColor.blackColor;
        cell.descrLabel.textColor  = UIColorFromRGB(color_text_footer);
        cell.backgroundColor = UIColor.whiteColor;
        cell.imageView.tintColor = item[@"color"];
    }];
}

@end
