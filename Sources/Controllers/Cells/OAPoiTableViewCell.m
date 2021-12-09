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
#import "OAUtilities.h"

#define kCategoryCellIndex 0
#define kPoiCellIndex 1
#define kCellHeight 36
#define kImageWidth 38
#define kLabelOffsetsWidth 20
#define kLabelMinimumWidth 50.0
#define kCellHeightWithoutIcons 116
#define kCategoriesCellsSpacing 10

#define kEstimatedIcomWidth 48
#define kMinIconsSpacing 8

@implementation OAForcedLeftAlignCollectionViewLayout
{
    CGFloat _iconWidth;
    CGFloat _minIconsSpacing;
}

- (instancetype)initWithIconWidth:(CGFloat)iconWidth minIconsSpacing:(CGFloat)minIconsSpacing
{
    self = [super init];
    if (self)
    {
        _iconWidth = iconWidth;
        _minIconsSpacing = minIconsSpacing;
    }
    return self;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    CGFloat collectionViewWidth = rect.size.width;
    int iconsPerRowCount = floor(collectionViewWidth / (_iconWidth + _minIconsSpacing));
    self.minimumInteritemSpacing = (collectionViewWidth - (_iconWidth * iconsPerRowCount)) / (iconsPerRowCount - 1);
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    CGFloat leftMargin = self.sectionInset.left;
    CGFloat maxY = -1.0f;

    for (UICollectionViewLayoutAttributes *attribute in attributes)
    {
        if (attribute.frame.origin.y >= maxY)
        {
            leftMargin = self.sectionInset.left;
        }
        attribute.frame = CGRectMake(leftMargin, attribute.frame.origin.y, attribute.frame.size.width, attribute.frame.size.height);
        leftMargin += attribute.frame.size.width + self.minimumInteritemSpacing;
        maxY = MAX(CGRectGetMaxY(attribute.frame), maxY);
    }
    return attributes;
}

@end


@implementation OAPoiTableViewCell
{
    NSArray<NSString *> *_categoryNames;
    NSArray<NSString *> *_categoryTitles;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAPoiCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAPoiCollectionViewCell getCellIdentifier]];
    UICollectionViewFlowLayout *forcedLeftAlignLayout = [[OAForcedLeftAlignCollectionViewLayout alloc] initWithIconWidth:kEstimatedIcomWidth minIconsSpacing:kMinIconsSpacing];
    [self.collectionView setCollectionViewLayout:forcedLeftAlignLayout];
    

    self.categoriesCollectionView.delegate = self;
    self.categoriesCollectionView.dataSource = self;
    [self.categoriesCollectionView registerNib:[UINib nibWithNibName:[OAFoldersCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAFoldersCollectionViewCell getCellIdentifier]];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.sectionInset = UIEdgeInsetsMake(0, kCategoriesCellsSpacing, 0, 8);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.categoriesCollectionView setCollectionViewLayout:layout];
    [self.categoriesCollectionView setShowsHorizontalScrollIndicator:NO];
    [self.categoriesCollectionView setShowsVerticalScrollIndicator:NO];
    
    if ([self isDirectionRTL])
    {
        [self.collectionView setTransform:CGAffineTransformMakeScale(-1, 1)];
        [self.categoriesCollectionView setTransform:CGAffineTransformMakeScale(-1, 1)];
    }
    
    _categoryDataArray = [NSMutableArray new];
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

- (void) setCategoryDataArray:(NSArray *)categoryDataArray
{
    _categoryDataArray = categoryDataArray;
    [self updateCategoryNames];
}

- (void) updateCategoryNames
{
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *titles = [NSMutableArray new];
    for (NSDictionary *category in _categoryDataArray)
    {
        [names addObject:category[@"categoryName"]];
        [titles addObject:category[@"title"]];
    }
    _categoryNames = [NSArray arrayWithArray:names];
    _categoryTitles = [NSArray arrayWithArray:titles];
}

#pragma mark - Scroll offset calculations

- (void) updateContentOffset
{
    if (![_state containsValueForIndex:_cellIndex])
    {
        NSInteger selectedIndex = [_categoryNames indexOfObject:_currentCategory];
        CGPoint initialOffset = [self calculateOffset:selectedIndex];
        [_state setOffset:initialOffset forIndex:_cellIndex];
        self.categoriesCollectionView.contentOffset = initialOffset;
    }
    else
    {
        CGPoint loadedOffset = [_state getOffsetForIndex:_cellIndex];
        if ([OAUtilities getLeftMargin] > 0)
            loadedOffset.x += [OAUtilities getLeftMargin] - kCategoriesCellsSpacing;
        self.categoriesCollectionView.contentOffset = loadedOffset;
    }
}

- (void) saveOffset
{
    CGPoint offset = self.categoriesCollectionView.contentOffset;
    if ([OAUtilities getLeftMargin] > 0)
        offset.x -= [OAUtilities getLeftMargin] - kCategoriesCellsSpacing;
    [_state setOffset:offset forIndex:_cellIndex];
}

- (CGPoint) calculateOffset:(NSInteger)index
{
    CGPoint selectedOffset = [self calculateOffsetToSelectedIndex:index labels:_categoryTitles];
    CGPoint fullLength = [self calculateOffsetToSelectedIndex:_categoryNames.count labels:_categoryTitles];
    CGFloat maxOffset = fullLength.x - DeviceScreenWidth + kCategoriesCellsSpacing;
    if (selectedOffset.x > maxOffset)
        selectedOffset.x = maxOffset;

    return selectedOffset;
}

- (CGPoint) calculateOffsetToSelectedIndex:(NSInteger)index labels:(NSArray<NSString *> *)labels
{
    CGFloat offset = 0;
    for (NSInteger i = 0; i < index; i++)
    {
        offset += [self calculateCellWidth:labels[i] iconName:_categoryDataArray[i][@"img"]];
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

#pragma mark - UICollectionViewDataSource

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
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[OAFoldersCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCollectionViewCell getCellIdentifier] owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        if (cell && [cell isKindOfClass:OAFoldersCollectionViewCell.class])
        {
            OAFoldersCollectionViewCell *destCell = (OAFoldersCollectionViewCell *) cell;
            destCell.layer.cornerRadius = 9;
            destCell.titleLabel.text = item[@"title"];
            destCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);
            NSString *iconName = item[@"img"];

            BOOL hasIcon = iconName && iconName.length > 0;
            [destCell showImage:hasIcon];
            [destCell.imageView setImage:hasIcon ? [UIImage templateImageNamed:item[@"img"]] : nil];

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
        
        if ([self isDirectionRTL])
            [cell.contentView setTransform:CGAffineTransformMakeScale(-1, 1)];

        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];

        return cell;
    }
    else
    {
        OAPoiCollectionViewCell* cell = nil;
        cell = (OAPoiCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[OAPoiCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
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
        if ([self isDirectionRTL])
            [cell.contentView setTransform:CGAffineTransformMakeScale(-1, 1)];
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
    if (collectionView.tag == kCategoryCellIndex)
    {
        NSDictionary *item = _categoryDataArray[indexPath.row];
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

#pragma mark - UICollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self saveOffset];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self saveOffset];
}

@end
