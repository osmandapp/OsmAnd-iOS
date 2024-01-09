//
//  OAFoldersCollectionView.mm
//  OsmAnd
//
//  Created by Skalii on 06.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAFoldersCollectionView.h"
#import "OAFoldersCollectionViewCell.h"
#import "OACollectionViewCellState.h"
#import "OACollectionViewFlowLayout.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kCellHeight 36
#define kImageWidth 38
#define kLabelOffsetsWidth 20
#define kLabelMinWidth 50.0
#define kLabelMaxWidth 120.0
#define kMarginSide 16.
#define kMarginSpaceMin 8.

@interface OAFoldersCollectionView() <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation OAFoldersCollectionView
{
    NSArray<NSDictionary *> *_data;
    NSInteger _selectionIndex;
    BOOL _onlyIconCompact;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout*)collectionViewLayout
{
    self = [super initWithFrame:frame collectionViewLayout:collectionViewLayout];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.delegate = self;
    self.dataSource = self;
    [self registerNib:[UINib nibWithNibName:[OAFoldersCollectionViewCell getCellIdentifier] bundle:nil]
    forCellWithReuseIdentifier:[OAFoldersCollectionViewCell getCellIdentifier]];
    self.contentInset = UIEdgeInsetsMake(0., kMarginSide , 0., kMarginSide);

    OACollectionViewFlowLayout *layout = [[OACollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(6., 0, 6., 0);
    layout.minimumInteritemSpacing = 12.;
    [self setCollectionViewLayout:layout];
    [self setShowsHorizontalScrollIndicator:NO];
    [self setShowsVerticalScrollIndicator:NO];

    _data = [NSMutableArray array];
    _selectionIndex = 0;
}

- (void)setOnlyIconCompact:(BOOL)compact
{
    _onlyIconCompact = compact;
}

- (void)setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(NSInteger)index
{
    _data = values;
    _selectionIndex = index;
}

- (BOOL)hasValues
{
    return _data && _data.count > 0;
}

- (void)setSelectedIndex:(NSInteger)index
{
    _selectionIndex = index;
}

- (NSInteger)getSelectedIndex
{
    return _selectionIndex;
}

#pragma mark - Scroll offset calculations

- (void)updateContentOffset
{
    if (![self.state containsValueForIndex:_cellIndex])
    {
        CGPoint initialOffset = [self calculateOffset:_selectionIndex];
        [self.state setOffset:initialOffset forIndex:_cellIndex];
        self.contentOffset = initialOffset;
    }
    else
    {
        CGPoint loadedOffset = [self.state getOffsetForIndex:_cellIndex];
        if ([OAUtilities getLeftMargin] > 0)
            loadedOffset.x -= [OAUtilities getLeftMargin] - kMarginSide;
        self.contentOffset = loadedOffset;
    }
}

- (void)saveOffset
{
    CGPoint offset = self.contentOffset;
    if ([OAUtilities getLeftMargin] > 0)
        offset.x += [OAUtilities getLeftMargin] - kMarginSide;
    [self.state setOffset:offset forIndex:_cellIndex];
}

- (CGPoint)calculateOffset:(NSInteger)index
{
    CGPoint selectedOffset = [self calculateOffsetToSelectedIndex:index];
    CGPoint fullLength = [self calculateOffsetToSelectedIndex:_data.count];
    CGFloat maxOffset = fullLength.x - self.frame.size.width - [OAUtilities getLeftMargin] + kMarginSide;
    if (selectedOffset.x > maxOffset)
        selectedOffset.x = maxOffset;

    return selectedOffset;
}

- (CGPoint)calculateOffsetToSelectedIndex:(NSInteger)index
{
    CGFloat offset = 0;
    for (NSInteger i = 0; i < index; i++)
    {
        offset += [self calculateCellWidth:i] + kMarginSide;
    }
    return CGPointMake(offset, 0);
}

- (CGFloat)calculateCellWidth:(NSInteger)index
{
    CGFloat cellWidth;
    if (_onlyIconCompact)
    {
        cellWidth = (self.frame.size.width - [OAUtilities getLeftMargin] - (kMarginSide * 2) - (_data.count - 1) * kMarginSpaceMin) / _data.count;
        if (cellWidth < kImageWidth)
            cellWidth = kImageWidth;
    }
    else
    {
        NSDictionary *item = _data[index];
        CGSize labelSize = [OAUtilities calculateTextBounds:item[@"title"]
                                                      width:self.frame.size.width - [OAUtilities getLeftMargin]
                                                       font:[UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold]];
        cellWidth = labelSize.width;

        NSString *iconName = item[@"img"];
        if (iconName && iconName.length > 0)
            cellWidth += kImageWidth;
        else if (cellWidth < kLabelMinWidth)
            cellWidth = kLabelMinWidth;

        cellWidth += kLabelOffsetsWidth;

        if (cellWidth > kLabelMaxWidth)
            cellWidth = kLabelMaxWidth;
    }
    
    return cellWidth;
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
    UICollectionViewCell *cell =
            [collectionView dequeueReusableCellWithReuseIdentifier:[OAFoldersCollectionViewCell getCellIdentifier]
                                                      forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCollectionViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = nib[0];
    }
    if (cell && [cell isKindOfClass:OAFoldersCollectionViewCell.class])
    {
        OAFoldersCollectionViewCell *destCell = (OAFoldersCollectionViewCell *) cell;
        destCell.layer.cornerRadius = 9.;

        BOOL available = [item.allKeys containsObject:@"available"] ? [item[@"available"] boolValue] : YES;
        BOOL enabled = [item.allKeys containsObject:@"enabled"] ? [item[@"enabled"] boolValue] : YES;

        destCell.titleLabel.text = item[@"title"];
        destCell.titleLabel.font = enabled
                ? [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold]
                : [UIFont fontWithDescriptor:[destCell.titleLabel.font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold]
                                        size:15.];

        NSString *iconName = item[@"img"];
        BOOL hasIcon = iconName && iconName.length > 0;
        [destCell showImage:hasIcon];
        [destCell.imageView setImage:hasIcon ? [UIImage templateImageNamed:item[@"img"]] : nil];

        UIColor *backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
        BOOL selected = [item.allKeys containsObject:@"selected"]
                ? [item[@"selected"] boolValue]
                : indexPath.row == _selectionIndex;
        if (selected)
        {
            backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
            destCell.titleLabel.textColor = [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
            destCell.imageView.tintColor = [UIColor colorNamed:ACColorNameButtonIconColorPrimary];
            destCell.layer.borderWidth = 0.;
            destCell.layer.borderColor = UIColor.clearColor.CGColor;
        }
        else
        {
            if (available && !enabled)
                backgroundColor = UIColor.clearColor;
            else if (!available && enabled)
                backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary];

            destCell.titleLabel.textColor = available
            ? [UIColor colorNamed:ACColorNameButtonTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
            destCell.imageView.tintColor = available
                    ? [UIColor colorNamed:ACColorNameButtonIconColorSecondary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
            destCell.layer.borderWidth = enabled ? 0. : 1.;
            destCell.layer.borderColor = enabled ? UIColor.clearColor.CGColor : [UIColor colorNamed:ACColorNameButtonBgColorSecondary].CGColor;
        }

        [cell setBackgroundColor:backgroundColor];
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
                             [cell setBackgroundColor:[UIColor colorNamed:ACColorNameButtonBgColorSecondary]];
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
                                     ? [UIColor colorNamed:ACColorNameButtonBgColorPrimary]
                                                     : [UIColor colorNamed:ACColorNameButtonBgColorTertiary]];
                         }
                         completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    BOOL available = [item.allKeys containsObject:@"available"] ? [item[@"available"] boolValue] : YES;
    if (self.foldersDelegate)
    {
        if (available)
        {
            _selectionIndex = indexPath.row;
            [self.foldersDelegate onItemSelected:indexPath.row];
        }
        else
        {
            if ([self.foldersDelegate respondsToSelector:@selector(onDisabledItemSelected:)])
                [self.foldersDelegate onDisabledItemSelected:indexPath.row];
        }
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

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (_onlyIconCompact)
        return kMarginSpaceMin;
    else
        return ((UICollectionViewFlowLayout *) collectionViewLayout).minimumInteritemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    if (_onlyIconCompact)
        return kMarginSpaceMin;
    else
        return ((UICollectionViewFlowLayout *) collectionViewLayout).minimumInteritemSpacing;
}

@end
