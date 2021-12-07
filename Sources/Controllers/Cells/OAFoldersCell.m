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

#define kCellHeight 36
#define kImageWidth 38
#define kLabelOffsetsWidth 20
#define kLabelMinWidth 50.0
#define kLabelMaxWidth 120.0
#define kMargin 16

@interface OAFoldersCell() <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation OAFoldersCell
{
    NSArray<NSDictionary *> *_data ;
    NSInteger _selectionIndex;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerNib:[UINib nibWithNibName:[OAFoldersCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAFoldersCollectionViewCell getCellIdentifier]];
    _collectionView.contentInset = UIEdgeInsetsMake(0., kMargin , 0., kMargin);
    _data = [NSMutableArray array];
    _selectionIndex = 0;
}

- (void) setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(NSInteger)index
{
    _data = values;
    _selectionIndex = index;
}

#pragma mark - Scroll offset calculations

- (void) updateContentOffset
{
    if (![_state containsValueForIndex:_cellIndex])
    {
        CGPoint initialOffset = [self calculateOffset:_selectionIndex];
        [_state setOffset:initialOffset forIndex:_cellIndex];
        self.collectionView.contentOffset = initialOffset;
    }
    else
    {
        CGPoint loadedOffset = [_state getOffsetForIndex:_cellIndex];
        if ([OAUtilities getLeftMargin] > 0)
            loadedOffset.x -= [OAUtilities getLeftMargin] - kMargin;
        self.collectionView.contentOffset = loadedOffset;
    }
}

- (void) saveOffset
{
    CGPoint offset = self.collectionView.contentOffset;
    if ([OAUtilities getLeftMargin] > 0)
        offset.x += [OAUtilities getLeftMargin] - kMargin;
    [_state setOffset:offset forIndex:_cellIndex];
}

- (CGPoint) calculateOffset:(NSInteger)index
{
    CGPoint selectedOffset = [self calculateOffsetToSelectedIndex:index];
    CGPoint fullLength = [self calculateOffsetToSelectedIndex:_data.count];
    CGFloat maxOffset = fullLength.x - DeviceScreenWidth + kMargin;
    if (selectedOffset.x > maxOffset)
        selectedOffset.x = maxOffset;

    return selectedOffset;
}

- (CGPoint) calculateOffsetToSelectedIndex:(NSInteger)index
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self saveOffset];
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[OAFoldersCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCollectionViewCell getCellIdentifier] owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OAFoldersCollectionViewCell.class])
    {
        OAFoldersCollectionViewCell *destCell = (OAFoldersCollectionViewCell *) cell;
        destCell.titleLabel.text = item[@"title"];
        destCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);
        destCell.layer.cornerRadius = 9;
        NSString *iconName = item[@"img"];
        BOOL available = [item.allKeys containsObject:@"available"] ? [item[@"available"] boolValue] : YES;

        BOOL hasIcon = iconName && iconName.length > 0;
        [destCell showImage:hasIcon];
        [destCell.imageView setImage:hasIcon ? [UIImage templateImageNamed:item[@"img"]] : nil];

        if (indexPath.row == _selectionIndex)
        {
            [destCell setBackgroundColor:UIColorFromRGB(color_primary_purple)];
            destCell.titleLabel.textColor = UIColor.whiteColor;
            destCell.imageView.tintColor = UIColor.whiteColor;
        }
        else
        {
            [destCell setBackgroundColor:available
                    ? UIColorFromARGB(color_primary_purple_10) : UIColorFromARGB(color_route_button_inactive)];
            destCell.titleLabel.textColor = available
                    ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer);
            destCell.imageView.tintColor = available
                    ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer);
        }
    }

    if ([cell needsUpdateConstraints])
        [cell setNeedsUpdateConstraints];

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    BOOL available = [item.allKeys containsObject:@"available"] ? [item[@"available"] boolValue] : YES;
    if (available)
    {
        UICollectionViewCell *cell = [colView cellForItemAtIndexPath:indexPath];
        [UIView animateWithDuration:0.2
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             [cell setBackgroundColor:UIColorFromRGB(color_tint_gray)];
                         }
                         completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)colView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    BOOL available = [item.allKeys containsObject:@"available"] ? [item[@"available"] boolValue] : YES;
    if (available)
    {
        UICollectionViewCell *cell = [colView cellForItemAtIndexPath:indexPath];
        [UIView animateWithDuration:0.2
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             [cell setBackgroundColor:indexPath.row == _selectionIndex
                                     ? UIColorFromRGB(color_primary_purple)
                                     : UIColorFromARGB(color_primary_purple_10)];
                         }
                         completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    BOOL available = [item.allKeys containsObject:@"available"] ? [item[@"available"] boolValue] : YES;
    if (available)
    {
        if (self.foldersDelegate)
            [self.foldersDelegate onItemSelected:indexPath.row type:_data[_selectionIndex][@"type"]];
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat labelWidth = [self calculateCellWidth:indexPath.row];
    return CGSizeMake(labelWidth, kCellHeight);
}

@end
