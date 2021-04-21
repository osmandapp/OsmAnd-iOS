//
//  OAPoiTableViewCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPoiTableViewCell.h"
#import "OAPoiCollectionViewCell.h"
#import "OAFoldersCollectionViewCell.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OATargetInfoViewController.h"

#define kCategoryCellIndex 0
#define kPoiCellIndex 1
#define kDestCell @"OAFoldersCollectionViewCell"
#define kCellHeight 36
#define kImageWidth 38
#define kLabelOffsetsWidth 20
#define kLabelMinimumWidth 50.0
#define kCellHeightWithoutIcons 116
#define kCategoriesCellsSpacing 12

@implementation OAPoiTableViewCell
{
    OACollectionViewCellState *state;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"OAPoiCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"OAPoiCollectionViewCell"];
    
    self.categoriesCollectionView.delegate = self;
    self.categoriesCollectionView.dataSource = self;
    [self.categoriesCollectionView registerNib:[UINib nibWithNibName:kDestCell bundle:nil] forCellWithReuseIdentifier:kDestCell];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.sectionInset = UIEdgeInsetsMake(0, kCategoriesCellsSpacing, 0, 8);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.categoriesCollectionView setCollectionViewLayout:layout];
    [self.categoriesCollectionView setShowsHorizontalScrollIndicator:NO];
    [self.categoriesCollectionView setShowsVerticalScrollIndicator:NO];
    
    _categoryDataArray = [NSMutableArray new];
    _currentCategoryIndex = -1;
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    int fullHeight = kCellHeightWithoutIcons + self.collectionView.contentSize.height;
    self.contentView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, fullHeight);
    [self.contentView layoutIfNeeded];
    self.collectionViewHeight.constant = self.collectionView.contentSize.height;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) updateContentOffset
{
    CGPoint offset = [_state getOffsetForKey:_cellTag];
    if ([OAUtilities getLeftMargin] > 0)
        offset.x += [OAUtilities getLeftMargin] - kCategoriesCellsSpacing;
    self.categoriesCollectionView.contentOffset = offset;
}

- (void) saveOffset
{
    CGPoint offset = self.categoriesCollectionView.contentOffset;
    if ([OAUtilities getLeftMargin] > 0)
        offset.x -= [OAUtilities getLeftMargin] - kCategoriesCellsSpacing;
    [_state setOffset:offset forKey:_cellTag];
}

- (CGPoint) calculateShowingOffset:(NSInteger)index labels:(NSArray<NSString *> *)labels
{
    CGPoint selectedOffset = [self calculateOffset:index labels:labels];
    CGPoint fullLength = [self calculateOffset:labels.count labels:labels];
    CGFloat maxOffset = fullLength.x - DeviceScreenWidth + kCategoriesCellsSpacing;
    if (selectedOffset.x > maxOffset)
        selectedOffset.x = maxOffset;

    return selectedOffset;
}

- (CGPoint) calculateOffset:(NSInteger)index labels:(NSArray<NSString *> *)labels
{
    CGFloat offset = 0;
    for (NSInteger i = 0; i < index; i++)
    {
        offset += [self calculateCellWidth:labels[i] iconName:nil];
        offset += kCategoriesCellsSpacing;
    }
    return CGPointMake(offset, 0);
}

- (CGFloat) calculateCellWidth:(NSString *)lablel iconName:(NSString *)iconName
{
    CGSize labelSize = [OAUtilities calculateTextBounds:lablel width:DeviceScreenWidth font:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]];
    CGFloat labelWidth = labelSize.width;
    if (iconName && iconName.length > 0)
        labelWidth += kImageWidth;
    else if (labelWidth < kLabelMinimumWidth)
        labelWidth = kLabelMinimumWidth;
    
    labelWidth += kLabelOffsetsWidth;
    return labelWidth;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView.tag == kCategoryCellIndex)
        return _categoryDataArray.count;
    else
        return _poiData[_currentCategory].count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == kCategoryCellIndex)
    {
        NSDictionary *item = _categoryDataArray[indexPath.row];
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDestCell forIndexPath:indexPath];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDestCell owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        if (cell && [cell isKindOfClass:OAFoldersCollectionViewCell.class])
        {
            OAFoldersCollectionViewCell *destCell = (OAFoldersCollectionViewCell *) cell;
            destCell.layer.cornerRadius = 9;
            destCell.titleLabel.text = item[@"title"];
            destCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);
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
            
            NSString *categoryName = item[@"categoryName"];
            if ([categoryName isEqualToString:_currentCategory])
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
    else
    {
        static NSString* const identifierCell = @"OAPoiCollectionViewCell";
        OAPoiCollectionViewCell* cell = nil;
        cell = (OAPoiCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifierCell forIndexPath:indexPath];
        UIImage *img = nil;
        NSString *imgName = _poiData[_currentCategory][indexPath.row];
        img = [OAUtilities applyScaleFactorToImage:[UIImage imageNamed:[OAUtilities drawablePath:imgName]]];
        
        cell.iconImageView.image = [[OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:imgName]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.tintColor = UIColorFromRGB(color_icon_inactive);
        
        if ([_poiData[_currentCategory][indexPath.row] isEqualToString:_currentIcon])
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
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == kCategoryCellIndex)
    {
        NSDictionary *item = _categoryDataArray[indexPath.row];
        CGFloat labelWidth = [self calculateCellWidth:item[@"title"] iconName:item[@"img"]];
        return CGSizeMake(labelWidth, kCellHeight);
    }
    else
    {
        return CGSizeMake(48.0, 48.0);
    }
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveOffset];
    if (collectionView.tag == kCategoryCellIndex)
    {
        NSDictionary *item = _categoryDataArray[indexPath.row];
        _currentCategoryIndex = indexPath.row;
        _currentCategory = item[@"categoryName"];
        [self.categoriesCollectionView reloadData];
        [self.collectionView reloadData];

        if (self.delegate)
            [self.delegate onPoiCategorySelected:item[@"categoryName"] index:indexPath.row];
    }
    else
    {
        _currentIcon = _poiData[_currentCategory][indexPath.row];
        [self.collectionView reloadData];
        if (self.delegate)
            [self.delegate onPoiSelected: _poiData[_currentCategory][indexPath.row]];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self saveOffset];
}

@end
