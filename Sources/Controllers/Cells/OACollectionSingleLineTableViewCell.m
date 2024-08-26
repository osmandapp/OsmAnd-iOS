//
//  OACollectionSingleLineTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"
#import "OASizes.h"
#import "UITableViewCell+getTableView.h"

@interface OACollectionSingleLineTableViewCell () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIStackView *contentOutsideStackViewVertical;
@property (weak, nonatomic) IBOutlet UIStackView *topMarginStackView;
@property (weak, nonatomic) IBOutlet UIStackView *collectionStackView;
@property (weak, nonatomic) IBOutlet UIStackView *bottomMarginStackView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@end

@implementation OACollectionSingleLineTableViewCell
{
    OABaseCollectionHandler *_collectionHandler;
    UITapGestureRecognizer *_tapRecognizer;
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(0., kPaddingOnSideOfContent , 0., 0.);

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRightActionButtonPressed:)];
    [self addGestureRecognizer:_tapRecognizer];
    _tapRecognizer.delegate = self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self.collectionView reloadData];
}

- (OABaseCollectionHandler *)getCollectionHandler
{
    return _collectionHandler;
}

- (void)setCollectionHandler:(OABaseCollectionHandler *)collectionHandler
{
    _collectionHandler = collectionHandler;

    NSString *cellIdentifier = [_collectionHandler getCellIdentifier];
    if (cellIdentifier)
    {
        [self.collectionView registerNib:[UINib nibWithNibName:cellIdentifier bundle:nil]
              forCellWithReuseIdentifier:cellIdentifier];
    }

    [self.collectionView performBatchUpdates:^{
        for (NSInteger i = 0; i < self.collectionView.numberOfSections; i ++)
        {
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:i]];
        }
    } completion:^(BOOL finished) {
        UICollectionViewScrollDirection scrollDirection = [_collectionHandler getScrollDirection];
        BOOL isHorizontal = scrollDirection == UICollectionViewScrollDirectionHorizontal;
        dispatch_async(dispatch_get_main_queue(), ^{
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.scrollDirection = scrollDirection;
            layout.itemSize = [_collectionHandler getItemSize];
            [self.collectionView setCollectionViewLayout:layout animated:!_disableAnimationsOnStart];

            NSIndexPath *selectedIndexPath = [_collectionHandler getSelectedIndexPath];
            if (selectedIndexPath.row != NSNotFound
                && ![self.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath]
                && selectedIndexPath.section < [collectionHandler sectionsCount]
                && selectedIndexPath.row < [collectionHandler itemsCount:selectedIndexPath.section])
            {
                [self.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                            atScrollPosition:isHorizontal
                    ? UICollectionViewScrollPositionCenteredHorizontally
                    : UICollectionViewScrollPositionCenteredVertically
                                                    animated:!_disableAnimationsOnStart];
            }
        });
    }];
}

- (CGFloat)getLeftInsetToView:(UIView *)view
{
    CGRect viewFrame = [view convertRect:view.bounds toView:self];
    return [self isDirectionRTL] ? ([self getTableView].frame.size.width - (viewFrame.origin.x + viewFrame.size.width)) : viewFrame.origin.x;
}

#pragma mark - Base UI

- (void)rightActionButtonVisibility:(BOOL)show
{
    self.rightActionButton.hidden = !show;

    if (show)
    {
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRightActionButtonPressed:)];
        [self addGestureRecognizer:_tapRecognizer];
        _tapRecognizer.delegate = self;
    }
    else if (_tapRecognizer)
    {
        [self removeGestureRecognizer:_tapRecognizer];
        _tapRecognizer = nil;
    }
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

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView
    contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath
                                         point:(CGPoint)point
{
    if (_collectionHandler)
    {
        UIMenu *contextMenu = [_collectionHandler getMenuForItem:indexPath collectionView:collectionView];
        if (contextMenu)
        {
            return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                           previewProvider:nil
                                                            actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
                return contextMenu;
            }];
        }
    }
    return nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _collectionHandler ? [_collectionHandler itemsCount:section] : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _collectionHandler ? [_collectionHandler getCollectionViewCell:indexPath] : nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _collectionHandler ? [_collectionHandler sectionsCount] : 0;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_collectionHandler)
        [_collectionHandler onItemSelected:indexPath collectionView:collectionView];
}

#pragma mark - Selectors

- (void)onRightActionButtonPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
        [self.delegate onRightActionButtonPressed:self.rightActionButton.tag];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.rightActionButton.hidden || !self.rightActionButton.enabled)
        return NO;

    CGFloat leftInset = [self getLeftInsetToView:self.rightActionButton];
    CGFloat pressedXLocation = [gestureRecognizer locationInView:self].x;
    if ([self isDirectionRTL])
        return [self getTableView].frame.size.width - pressedXLocation >= (leftInset - self.collectionStackView.spacing);
    else
        return pressedXLocation >= (leftInset - self.collectionStackView.spacing);
}

@end
