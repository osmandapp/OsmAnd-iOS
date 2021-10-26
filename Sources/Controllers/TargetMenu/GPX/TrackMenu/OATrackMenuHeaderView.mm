//
//  OATrackMenuHeaderView.mm
//  OsmAnd
//
//  Created by Skalii on 15.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHeaderView.h"
#import "OARouteDetailsGraphViewController.h"
#import "OAGpxStatBlockCollectionViewCell.h"
#import "OAColors.h"

#define kBlockStatistickHeight 40.
#define kBlockStatistickWidthMin 80.
#define kBlockStatistickWidthMinByValue 60.
#define kBlockStatistickWidthMax 120.
#define kBlockStatistickWidthMaxByValue 100.
#define kBlockStatistickDivider 13.

@implementation OATrackMenuHeaderView
{
    NSArray *_collectionData;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self)
        {
            [self commonInit];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self)
        {
            self.frame = frame;
            [self commonInit];
        }
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAGpxStatBlockCollectionViewCell getCellIdentifier] bundle:nil]
          forCellWithReuseIdentifier:[OAGpxStatBlockCollectionViewCell getCellIdentifier]];
}

- (void)commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)updateConstraints
{
    BOOL hasDescription = !self.descriptionContainerView.hidden;
    BOOL hasCollection = !self.collectionView.hidden;
    BOOL hasContent = hasCollection || !self.locationContainerView.hidden || !self.actionButtonsContainerView.hidden;
    BOOL isOnlyTitleAndDescription = hasDescription && !hasContent;
    BOOL isOnlyTitle = !hasDescription && !hasContent;
    BOOL hasDirection = !self.directionContainerView.hidden;

    self.onlyTitleAndDescriptionConstraint.active = isOnlyTitleAndDescription;
    self.onlyTitleNoDescriptionConstraint.active = isOnlyTitle;

    self.titleBottomDescriptionConstraint.active = hasDescription;
    self.titleBottomNoDescriptionConstraint.active = !hasDescription && hasCollection;
    self.titleBottomNoDescriptionNoCollectionConstraint.active =
            !hasDescription && !hasCollection && !isOnlyTitleAndDescription && !isOnlyTitle;

    self.descriptionBottomCollectionConstraint.active = hasCollection;
    self.descriptionBottomNoCollectionConstraint.active = !hasCollection;

    self.regionDirectionConstraint.active = hasDirection;
    self.regionNoDirectionConstraint.active = !hasDirection;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionContainerView.hidden;
        BOOL hasCollection = !self.collectionView.hidden;
        BOOL hasContent = hasCollection || !self.locationContainerView.hidden || !self.actionButtonsContainerView.hidden;
        BOOL isOnlyTitleAndDescription = hasDescription && !hasContent;
        BOOL isOnlyTitle = !hasDescription && !hasContent;
        BOOL hasDirection = !self.directionContainerView.hidden;

        res = res || self.onlyTitleAndDescriptionConstraint.active != isOnlyTitleAndDescription;
        res = res || self.onlyTitleNoDescriptionConstraint.active != isOnlyTitle;

        res = res || self.titleBottomDescriptionConstraint.active != hasDescription;
        res = res || self.titleBottomNoDescriptionConstraint.active != !hasDescription && hasCollection;
        res = res || self.titleBottomNoDescriptionNoCollectionConstraint.active !=
                !hasDescription && !hasCollection && !isOnlyTitleAndDescription && !isOnlyTitle;

        res = res || self.descriptionBottomCollectionConstraint.active != hasDescription && hasCollection;
        res = res || self.descriptionBottomNoCollectionConstraint.active != hasDescription && !hasCollection;

        res = res || self.regionDirectionConstraint.active != hasDirection;
        res = res || self.regionNoDirectionConstraint.active != !hasDirection;
    }
    return res;
}

- (void)updateFrame
{
    CGRect headerFrame = self.frame;

    if (self.onlyTitleAndDescriptionConstraint.active)
    {
        headerFrame.size.height =
                self.descriptionContainerView.frame.origin.y + self.descriptionContainerView.frame.size.height;
    }
    else if (self.onlyTitleNoDescriptionConstraint.active)
    {
        headerFrame.size.height = self.titleContainerView.frame.size.height;
    }
    else {
        if (self.descriptionContainerView.hidden)
            headerFrame.size.height -= self.descriptionContainerView.frame.size.height;

        if (self.locationContainerView.hidden)
            headerFrame.size.height -= self.locationContainerView.frame.size.height;

        if (self.collectionView.hidden)
            headerFrame.size.height -= self.collectionView.frame.size.height;

        if (self.actionButtonsContainerView.hidden)
            headerFrame.size.height -= self.actionButtonsContainerView.frame.size.height;
    }

    self.frame = headerFrame;
}

- (void)setDirection:(NSString *)direction
{
    BOOL hasDirection = direction && direction.length > 0;

    [self.directionTextView setText:direction];
    self.directionContainerView.hidden = !hasDirection;
    self.locationSeparatorView.hidden = !hasDirection;
}

- (void)setDescription:(NSString *)description
{
    BOOL hasDescription = description && description.length > 0;

    [self.descriptionView setText:description];
    self.descriptionContainerView.hidden = !hasDescription;
}

- (void)setCollection:(NSArray *)data
{
    BOOL hasData = data && data.count > 0;

    _collectionData = data;
    [self.collectionView reloadData];
    self.collectionView.hidden = !hasData;
}

- (void)makeOnlyHeader:(BOOL)hasDescription
{
    self.descriptionContainerView.hidden = !hasDescription;
    self.collectionView.hidden = YES;
    self.locationContainerView.hidden = YES;
    self.actionButtonsContainerView.hidden = YES;
}

- (void)showLocation:(BOOL)show
{
    self.locationContainerView.hidden = !show;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _collectionData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                   cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _collectionData[indexPath.row];
    OAGpxStatBlockCollectionViewCell *cell =
            [collectionView dequeueReusableCellWithReuseIdentifier:[OAGpxStatBlockCollectionViewCell getCellIdentifier]
                    forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAGpxStatBlockCollectionViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = nib[0];
    }
    if (cell)
    {
        [cell.valueView setText:item[@"value"]];
        cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
        cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        [cell.titleView setText:item[@"title"]];

        cell.separatorView.hidden =
                indexPath.row == [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1;

        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _collectionData[indexPath.row];
    BOOL isLast = indexPath.row == [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1;
    return [self getSizeForItem:item[@"title"] value:item[@"value"] isLast:isLast];
}

- (CGSize)getSizeForItem:(NSString *)title value:(NSString *)value isLast:(BOOL)isLast
{
    CGSize sizeByTitle = [OAUtilities calculateTextBounds:title
                                                    width:kBlockStatistickWidthMax
                                                   height:kBlockStatistickHeight
                                                     font:[UIFont systemFontOfSize:13. weight:UIFontWeightRegular]];
    CGSize sizeByValue = [OAUtilities calculateTextBounds:value
                                                    width:kBlockStatistickWidthMaxByValue
                                                   height:kBlockStatistickHeight
                                                     font:[UIFont systemFontOfSize:13. weight:UIFontWeightMedium]];
    CGFloat widthByTitle = sizeByTitle.width < kBlockStatistickWidthMin
            ? kBlockStatistickWidthMin : sizeByTitle.width > kBlockStatistickWidthMax
                    ? kBlockStatistickWidthMax : sizeByTitle.width;
    CGFloat widthByValue = (sizeByValue.width < kBlockStatistickWidthMinByValue
            ? kBlockStatistickWidthMinByValue : sizeByValue.width > kBlockStatistickWidthMaxByValue
                    ? kBlockStatistickWidthMaxByValue : sizeByValue.width)
                            + kBlockStatistickWidthMax - kBlockStatistickWidthMaxByValue;
    if (!isLast)
    {
        widthByTitle += kBlockStatistickDivider;
        widthByValue += kBlockStatistickDivider;
    }
    return CGSizeMake(MAX(widthByTitle, widthByValue), kBlockStatistickHeight);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _collectionData[indexPath.row];
    EOARouteStatisticsMode modeType = (EOARouteStatisticsMode) [item[@"type"] integerValue];
    if (self.trackMenuDelegate)
        [self.trackMenuDelegate openAnalysis:modeType];
}

@end
