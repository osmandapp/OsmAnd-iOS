//
//  OAFoldersCell.m
//  OsmAnd
//
//  Created by nnngrach on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFoldersCell.h"
#import "OAFoldersCollectionViewCell.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OACollectionViewCellState.h"

#define kDestCell @"OAFoldersCollectionViewCell"
#define kCellHeight 36
#define kImageWidth 38
#define kLabelOffsetsWidth 20
#define kLabelMinWidth 50.0
#define kLabelMaxWidth 120.0
#define kMargin 16

@interface OAFoldersCell() <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation OAFoldersCell
{
    NSMutableArray *_data;
    int _selectionIndex;
    BOOL _isFirstLoad;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerNib:[UINib nibWithNibName:kDestCell bundle:nil] forCellWithReuseIdentifier:kDestCell];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [_collectionView setCollectionViewLayout:layout];
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    _data = [NSMutableArray new];
    _selectionIndex = 0;
    _isFirstLoad = YES;
}

- (void) setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(int)index
{
    _data = values;
    _selectionIndex = index;
}

- (void) updateContentOffset
{
    CGPoint offset = [_state getOffsetForIndex:_cellIndex];
    if ([OAUtilities getLeftMargin] > 0)
        offset.x -= [OAUtilities getLeftMargin] - kMargin;
    self.collectionView.contentOffset = offset;
}

- (void) saveOffset
{
    CGPoint offset = self.collectionView.contentOffset;
    if ([OAUtilities getLeftMargin] > 0)
        offset.x += [OAUtilities getLeftMargin] - kMargin;
    [_state setOffset:offset forIndex:_cellIndex];
}

- (CGPoint) calculateShowingOffset:(NSInteger)index
{
    CGPoint selectedOffset = [self calculateOffset:index];
    CGPoint fullLength = [self calculateOffset:_data.count];
    CGFloat maxOffset = fullLength.x - DeviceScreenWidth + kMargin;
    if (selectedOffset.x > maxOffset)
        selectedOffset.x = maxOffset;

    return selectedOffset;
}

- (CGPoint) calculateOffset:(NSInteger)index
{
    CGFloat offset = 0;
    for (NSInteger i = 0; i < index; i++)
    {
        offset += [self calculateCellWidth:i] + kMargin;
    }
    return CGPointMake(offset, 0);
}

- (CGFloat) calculateCellWidth:(NSInteger)index
{
    NSDictionary *item = _data[index];
    CGSize labelSize = [OAUtilities calculateTextBounds:item[@"title"] width:DeviceScreenWidth font:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]];
    CGFloat labelWidth = labelSize.width;
    
    NSString *iconName = item[@"img"];
    if (iconName && iconName.length > 0)
        labelWidth += kImageWidth;
    else if (labelWidth < kLabelMinWidth)
        labelWidth = kLabelMinWidth;
    
    labelWidth += kLabelOffsetsWidth;
    
    if (labelWidth > kLabelMaxWidth)
        labelWidth = kLabelMaxWidth;
    
    return labelWidth;
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
    CGFloat labelWidth = [self calculateCellWidth:indexPath.row];    
    return CGSizeMake(labelWidth, kCellHeight);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDestCell forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDestCell owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OAFoldersCollectionViewCell.class])
    {
        OAFoldersCollectionViewCell *destCell = (OAFoldersCollectionViewCell *) cell;
        destCell.titleLabel.text = item[@"title"];
        destCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);
        destCell.layer.cornerRadius = 9;
        NSString *iconName = item[@"img"];
        if (iconName && iconName.length > 0)
        {
            [destCell.imageView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            destCell.imageView.hidden = NO;
            destCell.labelNoIconConstraint.priority = 1;
            destCell.labelWithIconConstraint.priority = 1000;
        }
        else
        {
            destCell.imageView.hidden = YES;
            destCell.labelNoIconConstraint.priority = 1000;
            destCell.labelWithIconConstraint.priority = 1;
        }
        
        if (indexPath.row == _selectionIndex)
        {
            destCell.layer.backgroundColor = UIColorFromRGB(color_primary_purple).CGColor;
            destCell.titleLabel.textColor = UIColor.whiteColor;
            destCell.imageView.tintColor = UIColor.whiteColor;
        }
        else
        {
            destCell.layer.backgroundColor = UIColorFromARGB(color_primary_purple_10).CGColor;
            destCell.titleLabel.textColor = UIColorFromRGB(color_primary_purple);
            destCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:UIColorFromRGB(color_tint_gray)];
    }
                     completion:nil];
}

- (void)collectionView:(UICollectionView *)colView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [colView reloadData];
    }
                     completion:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, kMargin, kMargin, kMargin);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_delegate)
        [_delegate onItemSelected:(int)indexPath.row type:_data[indexPath.row][@"type"]];
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self saveOffset];
}

@end
