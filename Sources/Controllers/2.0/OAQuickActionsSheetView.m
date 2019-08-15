//
//  OAQuickActionsSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionsSheetView.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAQuickActionCell.h"
#import "OAColors.h"
#import "OAQuickAction.h"
#import "OANewAction.h"

#define kButtonContainerHeight 60.0
#define kMargin 16.0
#define kButtonSpacing 13.0

#define kActionCellIdentifier @"OAQuickActionCell"

@interface OAQuickActionsSheetView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *topSliderView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *pageControlsContainer;
@property (weak, nonatomic) IBOutlet UIButton *controlBtnPrev;
@property (weak, nonatomic) IBOutlet UIButton *controlBtnNext;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControlIndicator;
@property (weak, nonatomic) IBOutlet UIView *closeBtnContainer;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@end

@implementation OAQuickActionsSheetView

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OAQuickActionsSheetView class]])
            self = (OAQuickActionsSheetView *)v;
    }
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OAQuickActionsSheetView class]])
        {
            self = (OAQuickActionsSheetView *) v;
        }
    }
    
    if (self)
    {
        [self commonInit];
        self.frame = frame;
    }
    
    return self;
}

- (void) commonInit
{
    _topSliderView.layer.cornerRadius = 3.;
    _closeBtn.layer.cornerRadius = 9.;
    _controlBtnPrev.layer.cornerRadius = 9.;
    _controlBtnNext.layer.cornerRadius = 9.;
    [_controlBtnPrev setImage:[[UIImage imageNamed:@"ic_custom_arrow_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_controlBtnNext setImage:[[UIImage imageNamed:@"ic_custom_arrow_forward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [self setupButton:_controlBtnPrev active:NO];
    // TODO infer from array of actions
    [self setupButton:_controlBtnNext active:YES];
//    [_pageControlIndicator setNumberOfPages:3];
    [_pageControlIndicator setCurrentPage:0];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.;
    layout.minimumLineSpacing = 0.;
    layout.sectionInset = UIEdgeInsetsZero;
    [_collectionView setCollectionViewLayout:layout];
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [self registerSupportedNibs];
}

- (void)didMoveToWindow
{
    [self setupButton:_controlBtnPrev active:NO];
    [self setupButton:_controlBtnNext active:YES];
    [_pageControlIndicator setCurrentPage:0];
    [_collectionView reloadData];
}

- (void) registerSupportedNibs
{
    [_collectionView registerNib:[UINib nibWithNibName:kActionCellIdentifier bundle:nil]
      forCellWithReuseIdentifier:kActionCellIdentifier];
}

- (void) setupButton:(UIButton *)button active:(BOOL)active
{
    [button setBackgroundColor:active ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_quick_action_background)];
    [button setTintColor:active ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [button setTitleColor:active ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self adjustFrame];
}

- (void) adjustFrame
{
    CGRect f = self.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    BOOL isLandscape = [OAUtilities isLandscape];
    
    CGFloat w = isLandscape ? DeviceScreenWidth / 2 : DeviceScreenWidth;
    CGFloat h = 0;
    
    CGRect sliderFrame = _topSliderView.frame;
    sliderFrame.origin.x = w / 2 - sliderFrame.size.width / 2;
    _topSliderView.frame = sliderFrame;
    
    CGRect actionsFrame = _collectionView.frame;
    actionsFrame.size.width = w;
    actionsFrame.size.height = 200.0;
    _collectionView.frame = actionsFrame;
    
    _pageControlsContainer.frame = CGRectMake(0.0, CGRectGetMaxY(actionsFrame), w, kButtonContainerHeight);
    _closeBtnContainer.frame = CGRectMake(0.0, CGRectGetMaxY(_pageControlsContainer.frame), w, kButtonContainerHeight + bottomMargin);
    
    CGFloat buttonY = kButtonContainerHeight / 2 - _controlBtnPrev.frame.size.height / 2;
    CGFloat buttonWidth = (w - _pageControlIndicator.frame.size.width) / 2 - kMargin - kButtonSpacing;
    CGFloat buttonHeight = _controlBtnPrev.frame.size.height;
    _controlBtnPrev.frame = CGRectMake(kMargin, buttonY, buttonWidth, buttonHeight);
    CGRect indicatorFrame = _pageControlIndicator.frame;
    CGPoint indicatorOrigin = CGPointMake(CGRectGetMaxX(_controlBtnPrev.frame) + kButtonSpacing,
                                          kButtonContainerHeight / 2 - _pageControlIndicator.frame.size.height / 2);
    indicatorFrame.origin = indicatorOrigin;
    _pageControlIndicator.frame = indicatorFrame;
    _controlBtnNext.frame = CGRectMake(CGRectGetMaxX(indicatorFrame) + kButtonSpacing, buttonY, buttonWidth, buttonHeight);
    
    _closeBtn.frame = CGRectMake(kMargin, buttonY, w - kMargin * 2, buttonHeight);
    
    h = actionsFrame.origin.y + actionsFrame.size.height + _pageControlsContainer.frame.size.height + _closeBtnContainer.frame.size.height;
    
    f.origin = CGPointMake(OAUtilities.getLeftMargin, DeviceScreenHeight - h);
    f.size.height = h;
    f.size.width = w;
    self.frame = f;
    
    [_collectionView.collectionViewLayout invalidateLayout];
    NSIndexPath *indexPath = _collectionView.indexPathsForVisibleItems.firstObject;
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    [OAUtilities setMaskTo:self byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
}

- (void)updateControlButtons:(NSIndexPath *)indexPath
{
    [self setupButton:_controlBtnPrev active:indexPath.section > 0];
    [self setupButton:_controlBtnNext active:indexPath.section + 1 < _collectionView.numberOfSections];
}

- (IBAction)controlPrevPressed:(id)sender
{
    NSIndexPath *indexPath = _collectionView.indexPathsForVisibleItems.firstObject;
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section - 1];
    if (indexPath.section > 0)
        [_collectionView scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    
    [_pageControlIndicator setCurrentPage:newIndexPath.section];
    [self updateControlButtons:newIndexPath];
}

- (IBAction)controlNextPressed:(id)sender
{
    NSIndexPath *indexPath = _collectionView.indexPathsForVisibleItems.firstObject;
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
    if (indexPath.section != _collectionView.numberOfSections - 1)
        [_collectionView scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    
    [_pageControlIndicator setCurrentPage:newIndexPath.section];
    [self updateControlButtons:newIndexPath];
}

- (IBAction)closePressed:(id)sender {
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    OANewAction *action = [[OANewAction alloc] init];
    [action execute];
    if (self.delegate)
        [_delegate dismissBottomSheet];
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:OAQuickActionCell.class])
    {
        OAQuickActionCell *selectedCell = (OAQuickActionCell *) cell;
        [UIView animateWithDuration:0.3 animations:^{
            selectedCell.layer.backgroundColor = UIColorFromRGB(color_coordinates_background).CGColor;
            selectedCell.imageView.tintColor = UIColor.whiteColor;
            selectedCell.actionTitleView.textColor = UIColor.whiteColor;
        } completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:OAQuickActionCell.class])
    {
        OAQuickActionCell *selectedCell = (OAQuickActionCell *) cell;
        [UIView animateWithDuration:0.2 animations:^{
            selectedCell.layer.backgroundColor = UIColor.clearColor.CGColor;
            selectedCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);;
            selectedCell.actionTitleView.textColor = UIColorFromRGB(color_quick_action_text);
        }];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 6;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.frame.size.width / 3, 100.);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kActionCellIdentifier forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kActionCellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OAQuickActionCell.class])
    {
        OAQuickActionCell *resultCell = (OAQuickActionCell *) cell;
        resultCell.backgroundColor = UIColor.clearColor;
        resultCell.actionTitleView.text = @"Add action";
        resultCell.imageView.image = [[UIImage imageNamed:@"zoom_in_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        resultCell.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    }
    
    return cell;
}

@end
