//
//  OAShapesTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAShapesTableViewCell.h"
#import "OAShapesCollectionViewCell.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

static NSString * const kOriginalKey = @"original";

@interface OAShapesTableViewCell () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTrailingWidth;
@property (weak, nonatomic) IBOutlet UIStackView *separatorStackView;
@property (weak, nonatomic) IBOutlet UIStackView *descriptionLabelStackView;

@end

@implementation OAShapesTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.separatorHeight.constant = 1.0 / [UIScreen mainScreen].scale;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:[OAShapesCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAShapesCollectionViewCell getCellIdentifier]];
    
    if ([self isDirectionRTL])
    {
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.valueLabel.textAlignment = NSTextAlignmentLeft;
    }
    else
    {
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.valueLabel.textAlignment = NSTextAlignmentRight;
    }
    
    [self topButtonVisibility:NO];
    [self separatorVisibility:NO];
    [self descriptionLabelStackViewVisibility:NO];
    [self topRightOffset:20];
}

- (ShapesCollectionHandler *)getColorCollectionHandler
{
    return (ShapesCollectionHandler *)[super getCollectionHandler];
}

- (void)setCollectionHandler:(OABaseCollectionHandler *)collectionHandler
{
    ShapesCollectionHandler * handler = (ShapesCollectionHandler *)collectionHandler;
    [super setCollectionHandler:handler];
    handler.hostCell = self;

    UIMenu *menu = [[self getColorCollectionHandler] buildTopButtonContextMenu];
    if (menu)
    {
        self.topButton.showsMenuAsPrimaryAction = YES;
        self.topButton.menu = menu;
    }
}

- (void)topButtonVisibility:(BOOL)show
{
    self.topButton.hidden = !show;
}

- (void)descriptionLabelStackViewVisibility:(BOOL)show
{
    self.descriptionLabelStackView.hidden = !show;
}

- (void)separatorVisibility:(BOOL)show
{
    self.separatorStackView.hidden = !show;
}

- (void)topRightOffset:(CGFloat)value
{
    self.topTrailingWidth.constant = value;
}

- (void)updateIconWith:(NSInteger)tag
{
    _currentIcon = tag;
    [self.collectionView reloadData];
    if (self.shapesTVCdelegate)
        [self.shapesTVCdelegate iconChanged:tag];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    self.contentView.frame = self.bounds;
    [self.contentView layoutIfNeeded];
    self.collectionViewHeight.constant = self.collectionView.contentSize.height;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _iconNames.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAShapesCollectionViewCell *cell = (OAShapesCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[OAShapesCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAShapesCollectionViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = nib[0];
    }
    if (cell)
    {
        cell.iconImageView.image = [UIImage templateImageNamed:_iconNames[indexPath.row]];
        cell.iconImageView.tintColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
        if (indexPath.row == _currentIcon)
        {
            cell.backgroundImageView.hidden = NO;
            cell.backgroundImageView.image = [UIImage templateImageNamed:_contourIconNames[indexPath.row]];
            cell.backgroundImageView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.iconImageView.tintColor = UIColorFromRGB(_currentColor);
        }
        else
        {
            cell.backgroundImageView.hidden = YES;
        }
    }
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(48.0, 48.0);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateIconWith:indexPath.row];
    ShapesCollectionHandler * handler = (ShapesCollectionHandler *)[self getCollectionHandler];
    if (handler)
        [handler selectCategory:handler.backgroundIconNames[indexPath.row] shouldPerformOnCategorySelected:false];
}

@end
