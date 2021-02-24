//
//  OABaseScrollableHudViewController.m
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OASizes.h"
#import "OAColors.h"

@interface OABaseScrollableHudViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UIView *topHeaderContainerView;

@end

@implementation OABaseScrollableHudViewController
{
    OAAppSettings *_settings;
    
    UIPanGestureRecognizer *_panGesture;
    
    BOOL _isDragging;
    BOOL _isHiding;
    BOOL _topOverScroll;
    CGFloat _initialTouchPoint;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseScrollableHudViewController"
                           bundle:nil];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // drop shadow
    [_scrollableView.layer setShadowColor:[UIColor blackColor].CGColor];
    [_scrollableView.layer setShadowOpacity:0.3];
    [_scrollableView.layer setShadowRadius:3.0];
    [_scrollableView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _topHeaderContainerView.layer.shadowColor = UIColor.blackColor.CGColor;
    _topHeaderContainerView.layer.shadowOpacity = 0.0;
    _topHeaderContainerView.layer.shadowRadius = 2.0;
    _topHeaderContainerView.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    _topHeaderContainerView.layer.masksToBounds = NO;
    
    if (self.useGestureRecognizer)
    {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragged:)];
        _panGesture.maximumNumberOfTouches = 1;
        _panGesture.minimumNumberOfTouches = 1;
        [_scrollableView addGestureRecognizer:_panGesture];
    }
    _currentState = EOADraggableMenuStateInitial;
    
    _sliderView.layer.cornerRadius = 3.;
    
    _closeButtonContainerView.layer.cornerRadius = 12.;
    _doneButtonContainerView.layer.cornerRadius = 12.;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self layoutSubviews];
    [self show:YES state:EOADraggableMenuStateInitial onComplete:nil];
}

- (void) applyCornerRadius:(BOOL)enable
{
    CGFloat value = enable ? 9. : 0.;
    _scrollableView.layer.cornerRadius = value;
    self.contentContainer.layer.cornerRadius = value;
}

- (void) setupModeViewShadowVisibility
{
    BOOL shouldShow = _tableView.contentOffset.y > 0;
    _topHeaderContainerView.layer.shadowOpacity = shouldShow ? 0.15 : 0.0;
}

- (void) commonInit
{
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self layoutSubviews];
    } completion:nil];
}

- (void) layoutSubviews
{
    if (_isDragging || _isHiding)
        return;
    
    BOOL isLandscape = [self isLandscape];
    _currentState = isLandscape ? EOADraggableMenuStateFullScreen : (!self.supportsFullScreen && _currentState == EOADraggableMenuStateFullScreen ? EOADraggableMenuStateExpanded : _currentState);
    
    [_tableView setScrollEnabled:_currentState == EOADraggableMenuStateFullScreen || (!self.supportsFullScreen && EOADraggableMenuStateExpanded)];
    
    [self adjustFrame];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if (isLandscape)
    {
        if (mapPanel.mapViewController.mapPositionX != 1)
        {
            mapPanel.mapViewController.mapPositionX = 1;
            [mapPanel refreshMap];
        }
    }
    else
    {
        if (mapPanel.mapViewController.mapPositionX != 0)
        {
            mapPanel.mapViewController.mapPositionX = 0;
            [mapPanel refreshMap];
        }
    }
    
    BOOL isFullScreen = _currentState == EOADraggableMenuStateFullScreen;
    _statusBarBackgroundView.frame = isFullScreen && [self showStatusBarWhenFullScreen] ? CGRectMake(0., 0., DeviceScreenWidth, OAUtilities.getStatusBarHeight) : CGRectZero;
    
    CGRect sliderFrame = _sliderView.frame;
    sliderFrame.origin.x = _scrollableView.bounds.size.width / 2 - sliderFrame.size.width / 2;
    _sliderView.frame = sliderFrame;
    
    CGRect buttonsFrame = _toolBarView.frame;
    buttonsFrame.size.width = _scrollableView.bounds.size.width;
    _toolBarView.frame = buttonsFrame;
    
    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = _scrollableView.bounds.size.width;
    contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
    contentFrame.size.height -= contentFrame.origin.y;
    _contentContainer.frame = contentFrame;
    
    _sliderView.hidden = isLandscape;
    
    _navbarLeadingConstraint.constant = isLandscape ? contentFrame.size.width : 0.;
    
    CGFloat tableViewY = CGRectGetMaxY(_topHeaderContainerView.frame);
    _tableView.frame = CGRectMake(0., tableViewY, contentFrame.size.width, contentFrame.size.height - tableViewY);
    
    _topHeaderContainerView.frame = CGRectMake(OAUtilities.getLeftMargin, _topHeaderContainerView.frame.origin.y, contentFrame.size.width - OAUtilities.getLeftMargin, _topHeaderContainerView.frame.size.height);
    
    [self applyCornerRadius:!isLandscape && _currentState != EOADraggableMenuStateFullScreen];
    
    [self onViewHeightChanged:self.getViewHeight];
}

- (CGFloat) additionalLandscapeOffset
{
    return OAUtilities.isIPad ? OAUtilities.getStatusBarHeight : 0.;
}

- (void) adjustFrame
{
    CGRect f = _scrollableView.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if ([self isLandscape])
    {
        f.origin = CGPointMake(0., self.additionalLandscapeOffset);
        f.size.height = DeviceScreenHeight - self.additionalLandscapeOffset;
        f.size.width = OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
        
        CGRect buttonsFrame = _toolBarView.frame;
        buttonsFrame.origin.y = f.size.height - 60. - bottomMargin;
        buttonsFrame.size.height = 60. + bottomMargin;
        _toolBarView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        _contentContainer.frame = contentFrame;
        
        _navbarLeadingConstraint.constant = contentFrame.size.width;
    }
    else
    {
        CGRect buttonsFrame = _toolBarView.frame;
        buttonsFrame.size.height = 60. + bottomMargin;
        f.size.height = [self getViewHeight];
        f.size.width = DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        
        buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
        _toolBarView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    _scrollableView.frame = f;
}

- (CGFloat)initialMenuHeight
{
    return 170.; // override
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight - DeviceScreenHeight / 4; // override
}

- (BOOL)supportsFullScreen
{
    return YES; // override
}

- (BOOL) useGestureRecognizer
{
    return YES;
}

- (BOOL) showStatusBarWhenFullScreen
{
    return NO;
}

- (CGFloat) getViewHeight:(EOADraggableMenuState)state
{
    switch (state) {
        case EOADraggableMenuStateInitial:
            return self.initialMenuHeight;
        case EOADraggableMenuStateExpanded:
            return self.expandedMenuHeight;
        case EOADraggableMenuStateFullScreen:
            return DeviceScreenHeight;
        default:
            return 0.0;
    }
}

- (CGFloat) getViewHeight
{
    return [self getViewHeight:_currentState];
}

- (CGPoint) calculateInitialPoint
{
    return CGPointMake(0., DeviceScreenHeight - [self getViewHeight]);
}

- (BOOL) isLandscape
{
    return OAUtilities.isLandscapeIpadAware;
}

- (CGFloat) getViewWidthForPad
{
    return OAUtilities.isLandscape ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad;
}

- (void) show:(BOOL)animated state:(EOADraggableMenuState)state onComplete:(void (^)(void))onComplete
{
    [_tableView setContentOffset:CGPointZero];
    _currentState = self.isLandscape ? EOADraggableMenuStateFullScreen : state;
    [_tableView setScrollEnabled:YES];
    
    [self adjustFrame];
    [self.tableView reloadData];

    if (animated)
    {
        CGRect frame = _scrollableView.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -_scrollableView.bounds.size.width;
            frame.origin.y = self.additionalLandscapeOffset;
            frame.size.width = OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
            _scrollableView.frame = frame;
            
            frame.origin.x = 0.0;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.origin.y = DeviceScreenHeight + 10.0;
            frame.size.width = DeviceScreenWidth;
            _scrollableView.frame = frame;
            
            frame.origin.y = DeviceScreenHeight - _scrollableView.bounds.size.height;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            _scrollableView.frame = frame;
        } completion:^(BOOL finished) {
            if (onComplete)
                onComplete();
        }];
    }
    else
    {
        CGRect frame = _scrollableView.frame;
        if ([self isLandscape])
            frame.origin.y = 0.0;
        else
            frame.origin.y = DeviceScreenHeight - _scrollableView.bounds.size.height;
        
        _scrollableView.frame = frame;
        
        if (onComplete)
            onComplete();
    }
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    _isHiding = YES;
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel setTopControlsVisible:YES];
    [mapPanel setBottomControlsVisible:YES menuHeight:0 animated:YES];

    _isHiding = YES;
    
    CGRect frame = _scrollableView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            _scrollableView.frame = frame;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:nil];
            if (onComplete)
                onComplete();
        }];
    }
    else
    {
        _scrollableView.frame = frame;
        [self dismissViewControllerAnimated:YES completion:nil];
        if (onComplete)
            onComplete();
    }
}

- (void)adjustMapViewPort
{
}

- (void) restoreMapViewPort
{
}

- (void) updateViewVisibility
{

}

#pragma mark - UIGestureRecognizerDelegate

- (void) onDragged:(UIPanGestureRecognizer *)recognizer
{
    CGFloat velocity = [recognizer velocityInView:self.view].y;
    BOOL slidingDown = velocity > 0;
    BOOL fastUpSlide = velocity < -1500.;
    BOOL fastDownSlide = velocity > 1500.;
    CGPoint touchPoint = [recognizer locationInView:self.view];
    CGPoint initialPoint = [self calculateInitialPoint];
    
    CGFloat expandedAnchor = DeviceScreenHeight / 4 + 40.;
    CGFloat fullScreenAnchor = OAUtilities.getStatusBarHeight + 40.;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _isDragging = YES;
            _initialTouchPoint = [recognizer locationInView:_scrollableView].y;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if (_scrollableView.frame.origin.y > OAUtilities.getStatusBarHeight
                || (_initialTouchPoint < _tableView.frame.origin.y && _tableView.contentOffset.y > 0))
            {
                [_tableView setContentOffset:CGPointZero];
            }
            
            if (newY <= OAUtilities.getStatusBarHeight || _tableView.contentOffset.y > 0)
            {
                newY = 0;
                if (_tableView.contentOffset.y > 0)
                    _initialTouchPoint = [recognizer locationInView:_scrollableView].y;
            }
            else if (DeviceScreenHeight - newY < _toolBarView.frame.size.height)
            {
                return;
            }
            
            CGRect frame = _scrollableView.frame;
            frame.origin.y = newY > 0 && newY <= OAUtilities.getStatusBarHeight ? OAUtilities.getStatusBarHeight : newY;
            frame.size.height = DeviceScreenHeight - newY;
            _scrollableView.frame = frame;
            
            _statusBarBackgroundView.frame = newY == 0 && [self showStatusBarWhenFullScreen] ? CGRectMake(0., 0., DeviceScreenWidth, OAUtilities.getStatusBarHeight) : CGRectZero;
            
            CGRect buttonsFrame = _toolBarView.frame;
            buttonsFrame.origin.y = frame.size.height - buttonsFrame.size.height;
            _toolBarView.frame = buttonsFrame;
            
            CGRect contentFrame = _contentContainer.frame;
            contentFrame.size.width = _scrollableView.bounds.size.width;
            contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
            contentFrame.size.height = frame.size.height - buttonsFrame.size.height - contentFrame.origin.y;
            _contentContainer.frame = contentFrame;
            
            CGFloat tableViewY = CGRectGetMaxY(_topHeaderContainerView.frame);
            _tableView.frame = CGRectMake(0., tableViewY, contentFrame.size.width, contentFrame.size.height - tableViewY);
            
            [self applyCornerRadius:newY > 0];
            return;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            BOOL shouldRefresh = NO;
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if ((newY - initialPoint.y > 180 || fastDownSlide) && _currentState == EOADraggableMenuStateInitial)
            {
                [self hide:YES duration:0.2 onComplete:nil];
                break;
            }
            else if (newY > DeviceScreenHeight - 170.0 + _toolBarView.frame.size.height + _tableView.frame.origin.y && !fastUpSlide)
            {
                shouldRefresh = YES;
                _currentState = EOADraggableMenuStateInitial;
            }
            else if ((newY < fullScreenAnchor || (!slidingDown && _currentState == EOADraggableMenuStateExpanded) || fastUpSlide) && self.supportsFullScreen)
            {
                _currentState = EOADraggableMenuStateFullScreen;
            }
            else if ((newY < expandedAnchor || (newY > expandedAnchor && !slidingDown)) && !fastDownSlide)
            {
                shouldRefresh = YES;
                _currentState = EOADraggableMenuStateExpanded;
            }
            else
            {
                shouldRefresh = YES;
                _currentState = EOADraggableMenuStateInitial;
            }
            [UIView animateWithDuration:0.2 animations:^{
                [self layoutSubviews];
            } completion:nil];
        }
        default:
        {
            break;
        }
    }
}

- (void) updateViewAnimated
{
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutSubviews];
    } completion:nil];
}

- (void) goExpanded
{
    _currentState = EOADraggableMenuStateExpanded;
    [self updateViewAnimated];
}

- (void) goMinimized
{
    _currentState = EOADraggableMenuStateInitial;
    [self updateViewAnimated];
}

- (void) goFullScreen
{
    _currentState = EOADraggableMenuStateFullScreen;
    [self updateViewAnimated];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![self isLandscape];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y <= 0)
        [scrollView setContentOffset:CGPointZero animated:NO];
    
    [self setupModeViewShadowVisibility];
}

#pragma mark - OADraggableViewMethods

- (void)onViewHeightChanged:(CGFloat)height
{
    //override
}

@end
