//
//  OACollectionSingleLineTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"
#import "OASizes.h"

@interface OACollectionSingleLineTableViewCell ()

@property (weak, nonatomic) IBOutlet UIStackView *contentOutsideStackViewVertical;
@property (weak, nonatomic) IBOutlet UIStackView *topMarginStackView;
@property (weak, nonatomic) IBOutlet UIStackView *collectionStackView;
@property (weak, nonatomic) IBOutlet UIStackView *bottomMarginStackView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@end

@implementation OACollectionSingleLineTableViewCell
{
    OABaseCollectionHandler *_collectionHandler;
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(0., kPaddingOnSideOfContent , 0., 0.);
}

- (OABaseCollectionHandler *)getCollectionHandler
{
    return _collectionHandler;
}

- (void)setCollectionHandler:(OABaseCollectionHandler *)collectionHandler
{
    _collectionHandler = collectionHandler;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = [_collectionHandler getScrollDirection];
    layout.itemSize = [_collectionHandler getItemSize];
    [self.collectionView setCollectionViewLayout:layout animated:YES];

    NSString *cellIdentifier = [_collectionHandler getCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:cellIdentifier bundle:nil] forCellWithReuseIdentifier:cellIdentifier];
    [self.collectionView scrollToItemAtIndexPath:[_collectionHandler getSelectedIndexPath]
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:YES];
}

#pragma mark - Base UI

- (void)buttonVisibility:(BOOL)show
{
    self.button.hidden = !show;
}

- (void)anchorContent:(EOATableViewCellContentStyle)style
{
    if (style == EOATableViewCellContentCenterStyle)
    {
        self.topMarginStackView.spacing = 16.;
        self.bottomMarginStackView.spacing = 16.;
    }
    else if (style == EOATableViewCellContentTopStyle)
    {
        self.topMarginStackView.spacing = 3.;
        self.bottomMarginStackView.spacing = 9.;
    }
}

#pragma mark - UIView

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
        withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
              verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    self.contentView.frame = self.bounds;
    [self.contentView layoutIfNeeded];
    CGFloat height = self.collectionView.contentSize.height;
    if (_collectionHandler)
    {
        CGSize itemSize = [_collectionHandler getItemSize];
        if (height < itemSize.height)
            height = itemSize.height;
    }
    self.collectionViewHeight.constant = height;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _collectionHandler ? [_collectionHandler rowsCount:section] : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _collectionHandler ? [_collectionHandler getCollectionViewCell:indexPath collectionView:collectionView] : nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _collectionHandler ? [_collectionHandler sectionsCount] : 0;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_collectionHandler)
        [_collectionHandler onRowSelected:indexPath collectionView:collectionView];
}

@end
