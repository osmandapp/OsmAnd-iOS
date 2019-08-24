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
#import "OAQuickActionRegistry.h"
#import "OAAutoObserverProxy.h"
#import "OAActionConfigurationViewController.h"

#define kButtonContainerHeight 60.0
#define kMargin 16.0
#define kButtonSpacing 13.0

#define kActionCellIdentifier @"OAQuickActionCell"

@interface OAQuickActionsSheetView () <UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate>

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
{
    NSArray<OAQuickAction *> *_actions;
    
    OAAutoObserverProxy* _actionsChangedObserver;
    
    UILongPressGestureRecognizer *_longPress;
}

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

- (void)setupPageControls {
    [_pageControlIndicator setNumberOfPages:[self getPagesCount]];
    [_pageControlIndicator setCurrentPage:0];
    [self setupButton:_controlBtnPrev active:NO];
    [self setupButton:_controlBtnNext active:_pageControlIndicator.numberOfPages > 1];
}

- (void) commonInit
{
    OAQuickActionRegistry *registry = [OAQuickActionRegistry sharedInstance];
    _actionsChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onActionsChanged)
                                                         andObserve:registry.quickActionListChangedObservable];
    
    NSMutableArray<OAQuickAction *> *tmpActions = [NSMutableArray arrayWithArray:registry.getQuickActions];
    [tmpActions addObject:[[OANewAction alloc] init]];
    _actions = [NSArray arrayWithArray:tmpActions];
    _topSliderView.layer.cornerRadius = 3.;
    _closeBtn.layer.cornerRadius = 9.;
    _controlBtnPrev.layer.cornerRadius = 9.;
    _controlBtnNext.layer.cornerRadius = 9.;
    [_controlBtnPrev setImage:[[UIImage imageNamed:@"ic_custom_arrow_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_controlBtnNext setImage:[[UIImage imageNamed:@"ic_custom_arrow_forward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [self setupPageControls];
    
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
    _collectionView.contentInset = UIEdgeInsetsMake(0., 0., 0., self.bounds.size.width);
    [self registerSupportedNibs];
    
    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _longPress.delegate = self;
    _longPress.delaysTouchesBegan = YES;
    [self.collectionView addGestureRecognizer:_longPress];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
        [self animateCellSelected:indexPath];
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    else
    {
        [self animateCellDeselected:indexPath];
        [self openQuickActionSetupFor:indexPath];
    }
}

- (void) openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickAction *item = [self getAction:indexPath];
    if (item.isActionEditable)
    {
        OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:item isNew:NO];
        [[OARootViewController instance].navigationController pushViewController:actionScreen animated:YES];
    }
    else
    {
        [item execute];
    }
    if (self.delegate)
        [_delegate dismissBottomSheet];
}

-(void)onActionsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray<OAQuickAction *> *tmpActions = [NSMutableArray arrayWithArray:[OAQuickActionRegistry sharedInstance].getQuickActions];
        [tmpActions addObject:[[OANewAction alloc] init]];
        _actions = [NSArray arrayWithArray:tmpActions];
        [_collectionView reloadData];
        [self setupPageControls];
    });
}

- (void)didMoveToWindow
{
    [self setupButton:_controlBtnPrev active:NO];
    [self setupButton:_controlBtnNext active:_pageControlIndicator.numberOfPages > 1];
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
    button.userInteractionEnabled = active;
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
    CGFloat maxHeight = isLandscape ? DeviceScreenHeight - OAUtilities.getStatusBarHeight : DeviceScreenHeight / 2;
    CGFloat h = 0;
    
    CGRect sliderFrame = _topSliderView.frame;
    sliderFrame.origin.x = w / 2 - sliderFrame.size.width / 2;
    _topSliderView.frame = sliderFrame;
    
    CGRect actionsFrame = _collectionView.frame;
    actionsFrame.size.width = w;
    actionsFrame.size.height = MIN(maxHeight - sliderFrame.size.height - (kButtonContainerHeight * 2) - bottomMargin, 200.);
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
    _collectionView.contentInset = UIEdgeInsetsMake(0., 0., 0., self.bounds.size.width);
    [OAUtilities setMaskTo:self byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
}

- (void)updateControlButtons:(NSIndexPath *)indexPath
{
    [self setupButton:_controlBtnPrev active:indexPath.section > 0];
    [self setupButton:_controlBtnNext active:indexPath.section + 1 < _collectionView.numberOfSections];
}

- (NSInteger)getPagesCount
{
    NSInteger numOfItems = _actions.count;
    BOOL oneSection = numOfItems / 6 < 1;
    BOOL hasRemainder = numOfItems % 6 != 0;
    if (oneSection)
        return 1;
    else
        return (numOfItems / 6) + (hasRemainder ? 1 : 0);
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
    if (self.delegate)
        [_delegate dismissBottomSheet];
}

- (OAQuickAction *) getAction:(NSIndexPath *)indexPath
{
    return _actions[6 * indexPath.section + indexPath.row];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAQuickAction *action = [self getAction:indexPath];
    [action execute];
    if (self.delegate)
        [_delegate dismissBottomSheet];
}

- (void)animateCellSelected:(NSIndexPath * _Nonnull)indexPath
{
    UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
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

- (void)animateCellDeselected:(NSIndexPath * _Nonnull)indexPath
{
    UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
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

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self animateCellSelected:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self animateCellDeselected:indexPath];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self getPagesCount];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    BOOL oneSection = _actions.count / 6 < 1;
    BOOL lastSection = section == _actions.count / 6;
    return oneSection || lastSection ? _actions.count % 6 : 6;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.frame.size.width / 3, _collectionView.frame.size.height / 2);
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
        OAQuickAction *action = [self getAction:indexPath];
        BOOL isEnabled = action.isActionEnabled;
        OAQuickActionCell *resultCell = (OAQuickActionCell *) cell;
        resultCell.userInteractionEnabled = isEnabled;
        resultCell.backgroundColor = UIColor.clearColor;
        resultCell.actionTitleView.text = action.getName;
        [resultCell.actionTitleView setEnabled:isEnabled];
        resultCell.imageView.image = [[UIImage imageNamed:action.getIconResName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        resultCell.imageView.tintColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:isEnabled ? 1.0 : 0.3];
        if (resultCell.imageView.subviews.count > 0)
            [[resultCell.imageView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (action.hasSecondaryIcon)
        {
            CGRect frame = CGRectMake(0., 0., resultCell.imageView.frame.size.width, resultCell.imageView.frame.size.height);
            UIImage *imgBackground = [[UIImage imageNamed:@"ic_custom_compound_action_background"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
            [background setTintColor:UIColorFromRGB(color_quick_action_background)];
            [resultCell.imageView addSubview:background];
            UIImage *img = [[UIImage imageNamed:action.getSecondaryIconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *view = [[UIImageView alloc] initWithImage:img];
            view.frame = frame;
            [resultCell.imageView addSubview:view];
        }
        if ([action isActionWithSlash])
        {
            CGRect frame = CGRectMake(0., 0., resultCell.imageView.frame.size.width, resultCell.imageView.frame.size.height);
            UIImage *imgBackground = [[UIImage imageNamed:@"ic_custom_compound_action_hide_bottom"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
            background.frame = frame;
            [background setTintColor:UIColorFromRGB(color_quick_action_background)];
            [resultCell.imageView addSubview:background];
            UIImage *img = [[UIImage imageNamed:@"ic_custom_compound_action_hide_top"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *view = [[UIImageView alloc] initWithImage:img];
            view.frame = frame;
            [resultCell.imageView addSubview:view];
        }
    }
    
    return cell;
}

@end
