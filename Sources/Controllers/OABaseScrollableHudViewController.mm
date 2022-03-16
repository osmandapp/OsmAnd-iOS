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
#import "OASizes.h"

@interface OABaseScrollableHudViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *sliderView;

@end

@implementation OABaseScrollableHudViewController
{
    OAAppSettings *_settings;
    
    UIPanGestureRecognizer *_panGesture;
    
    BOOL _isDragging;
    BOOL _isHiding;
    CGFloat _initialTouchPoint;
    CGFloat _tableViewContentOffsetY;
    BOOL _isDraggingOnTable;
    BOOL _firstStateChanged;
}

- (BOOL)hasCustomStatusBar
{
    return NO; //override
}

- (CGFloat)getStatusBarHeight
{
    return [self hasCustomStatusBar] ? _statusBarBackgroundView.frame.size.height : [OAUtilities getStatusBarHeight];
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
        _panGesture.delegate = self;
    }
    _currentState = [self hasInitialState] ? EOADraggableMenuStateInitial : EOADraggableMenuStateExpanded;
    _menuHudMode = EOAScrollableMenuHudBaseMode;

    _sliderView.layer.cornerRadius = 3.;
    _statusBarBackgroundView.hidden = ![self hasCustomStatusBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self show:YES state:_currentState onComplete:^{
        [self layoutSubviews];
    }];
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
    
    BOOL isLandscape = [self isLeftSidePresentation];
    [self updateLayoutCurrentState];
    
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

    if (![self hasCustomStatusBar])
    {
        BOOL showStatusBar = _currentState == EOADraggableMenuStateFullScreen && [self showStatusBarWhenFullScreen];
        _statusBarBackgroundView.frame = showStatusBar
                ? CGRectMake(0., 0., DeviceScreenWidth, [self getStatusBarHeight])
                : CGRectZero;
    }
    else
    {
        _statusBarBackgroundView.hidden = [self isLandscape];
    }

    UIView *customHeader = [self getCustomHeader];
    if (customHeader)
    {
        CGRect customHeaderFrame = customHeader.frame;
        customHeaderFrame.origin.y = [self hasCustomStatusBar] && ([self isLandscape] || _scrollableView.frame.origin.y > [self getStatusBarHeight])
                ? 0.
                : CGRectGetMaxY(_statusBarBackgroundView.frame);
        customHeader.frame = customHeaderFrame;
    }

    CGRect sliderFrame = _sliderView.frame;
    sliderFrame.origin.x = _scrollableView.bounds.size.width / 2 - sliderFrame.size.width / 2;
    _sliderView.frame = sliderFrame;
    
    CGRect buttonsFrame = _toolBarView.frame;
    buttonsFrame.size.width = _scrollableView.bounds.size.width;
    if ([self getToolbarHeight] == 0)
        buttonsFrame.size.height = 0.;
    _toolBarView.frame = buttonsFrame;
    
    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = _scrollableView.bounds.size.width;
    contentFrame.origin.y =  [self hasCustomStatusBar] && ([self isLandscape] || _scrollableView.frame.origin.y > [self getStatusBarHeight])
            ? 0.
            : CGRectGetMaxY(_statusBarBackgroundView.frame);
    contentFrame.size.height -= contentFrame.origin.y;
    _contentContainer.frame = contentFrame;
    
    _sliderView.hidden = isLandscape;
    
    CGFloat tableViewY = CGRectGetMaxY(_topHeaderContainerView.frame);
    _tableView.frame = CGRectMake(
            0.,
            [self hasCustomHeaderFooter] ? 0. : tableViewY,
            contentFrame.size.width,
            [self hasCustomHeaderFooter] ? contentFrame.size.height + self.toolBarView.frame.size.height
                    : contentFrame.size.height - tableViewY
    );

    _topHeaderContainerView.frame = CGRectMake(OAUtilities.getLeftMargin, _topHeaderContainerView.frame.origin.y, contentFrame.size.width - OAUtilities.getLeftMargin, _topHeaderContainerView.frame.size.height);
    
    [self applyCornerRadius:!isLandscape && _currentState != EOADraggableMenuStateFullScreen];

    [self onViewStateChanged:self.getViewHeight];
    
    [self doAdditionalLayout];
}

- (void) doAdditionalLayout
{
    //override
}

- (void) updateLayoutCurrentState
{
    _currentState = [self isLeftSidePresentation] ? EOADraggableMenuStateFullScreen : (!self.supportsFullScreen && _currentState == EOADraggableMenuStateFullScreen ? EOADraggableMenuStateExpanded : _currentState);
}

- (CGFloat) additionalLandscapeOffset
{
    return OAUtilities.isIPad && !OAUtilities.isWindowed ? [self getStatusBarHeight] : 0.;
}

- (void) adjustFrame
{
    CGRect f = _scrollableView.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    CGFloat toolbarHeight = [self getToolbarHeight];
    if ([self isLeftSidePresentation])
    {
        f.origin = CGPointMake(0., [self getLandscapeYOffset]);
        f.size.height = DeviceScreenHeight - self.additionalLandscapeOffset;
        f.size.width = [self getLandscapeViewWidth];
        
        CGRect buttonsFrame = _toolBarView.frame;
        buttonsFrame.size.height = toolbarHeight > 0 ? toolbarHeight + bottomMargin : 0.;
        buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
        _toolBarView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        _contentContainer.frame = contentFrame;
    }
    else
    {
        CGRect buttonsFrame = _toolBarView.frame;
        buttonsFrame.size.height = toolbarHeight > 0 && toolbarHeight != bottomMargin ? toolbarHeight + bottomMargin : toolbarHeight;
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

- (CGFloat) getToolbarHeight
{
    return 60.; // override
}

- (CGFloat) getNavbarHeight
{
    return 0;
}

- (CGFloat) getLandscapeYOffset
{
    return self.additionalLandscapeOffset;
}

- (UIView *)getCustomHeader
{
    return nil; //override
}

- (BOOL)hasInitialState
{
    return YES;
}

- (CGFloat)initialMenuHeight
{
    return _topHeaderContainerView.frame.origin.y + _topHeaderContainerView.frame.size.height + _toolBarView.frame.size.height; // override
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

- (CGFloat) getViewHeight
{
    return [self getViewHeight:_currentState];
}

- (CGFloat) getViewHeight:(EOADraggableMenuState)state
{
    switch (state)
    {
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

- (CGFloat) getLandscapeViewWidth
{
    return OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
}

- (CGPoint) calculateInitialPoint
{
    return CGPointMake(0., DeviceScreenHeight - [self getViewHeight]);
}

- (BOOL) isLandscape
{
    return OAUtilities.isLandscapeIpadAware;
}

- (BOOL) isLeftSidePresentation
{
    return OAUtilities.isLandscapeIpadAware;
}

- (BOOL) shouldScrollInAllModes
{
    return YES;
}

- (BOOL) hasCustomHeaderFooter
{
    return NO; //override
}

- (CGFloat) getViewWidthForPad
{
    return OAUtilities.isLandscape ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad;
}

- (void) show:(BOOL)animated state:(EOADraggableMenuState)state onComplete:(void (^)(void))onComplete
{
    [_tableView setContentOffset:CGPointZero];
    [self updateShowingState:state];
    [_tableView setScrollEnabled:YES];
    
    [self adjustFrame];
    [self.tableView reloadData];

    if (animated)
    {
        CGRect frame = _scrollableView.frame;
        if ([self isLeftSidePresentation])
        {
            frame.size.width = [self getLandscapeViewWidth];
            frame.origin.x = 0.0;

            if (self.menuHudMode == EOAScrollableMenuHudExtraHeaderInLandscapeMode)
                frame.origin.y = DeviceScreenHeight - self.additionalLandscapeOffset;
            else
                frame.origin.y = 0.0;

            _scrollableView.frame = frame;
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

        }];

        if (onComplete)
            onComplete();
    }
    else
    {
        CGRect frame = _scrollableView.frame;
        if ([self isLeftSidePresentation])
            frame.origin.y = 0.0;
        else
            frame.origin.y = DeviceScreenHeight - _scrollableView.bounds.size.height;
        
        _scrollableView.frame = frame;
        
        if (onComplete)
            onComplete();
    }
}

- (void) updateShowingState:(EOADraggableMenuState)state
{
    _currentState = self.isLeftSidePresentation ? EOADraggableMenuStateFullScreen : state;
}

- (BOOL)isFirstStateChanged
{
    return _firstStateChanged;
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
    CGFloat fullScreenAnchor = [self getStatusBarHeight] + 40.;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _isDragging = YES;
            _initialTouchPoint = [recognizer locationInView:_scrollableView].y;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            _tableViewContentOffsetY = _tableView.contentOffset.y;

            if (_isDraggingOnTable)
                _tableView.contentOffset = CGPointMake(0., 0.);
            
            if (_scrollableView.frame.origin.y > [self getStatusBarHeight]
                || (_initialTouchPoint < _tableView.frame.origin.y && _tableViewContentOffsetY > 0))
                _tableViewContentOffsetY = 0;
            
            if ((self.supportsFullScreen && _currentState != EOADraggableMenuStateFullScreen)
                    && (newY <= [self getStatusBarHeight] || _tableViewContentOffsetY > 0))
            {
                newY = 0;
                if (_tableViewContentOffsetY > 0)
                    _initialTouchPoint = [recognizer locationInView:_scrollableView].y;
            }
            else if ((DeviceScreenHeight - newY < _toolBarView.frame.size.height)
                    || newY <= 0
                    || (_currentState == EOADraggableMenuStateFullScreen && newY < [self getStatusBarHeight]))
            {
                return;
            }
            
            CGRect frame = _scrollableView.frame;
            frame.origin.y = newY > 0 && newY <= [self getStatusBarHeight] ? [self getStatusBarHeight] : newY;
            frame.size.height = DeviceScreenHeight - newY;
            _scrollableView.frame = frame;

            if (![self hasCustomStatusBar])
            {
                BOOL showStatusBar = (newY == 0 && [self showStatusBarWhenFullScreen]) || [self hasCustomStatusBar];
                _statusBarBackgroundView.frame = showStatusBar
                        ? CGRectMake(0., 0., DeviceScreenWidth, [self getStatusBarHeight])
                        : CGRectZero;
            }
            else
            {
                _statusBarBackgroundView.hidden = [self isLandscape];
            }

            UIView *customHeader = [self getCustomHeader];
            if (customHeader)
            {
                CGRect customHeaderFrame = customHeader.frame;
                customHeaderFrame.origin.y =  [self hasCustomStatusBar] && ([self isLandscape] || newY > [self getStatusBarHeight])
                        ? 0.
                        : CGRectGetMaxY(_statusBarBackgroundView.frame);
                customHeader.frame = customHeaderFrame;
            }
            
            BOOL hasToolbar = [self getToolbarHeight] > 0;
            CGRect buttonsFrame = _toolBarView.frame;
            if (_toolBarView.frame.size.height == [OAUtilities getBottomMargin] && !slidingDown)
                hasToolbar = NO;
            buttonsFrame.origin.y = hasToolbar ? (frame.size.height - buttonsFrame.size.height) : 0.;
            if (!hasToolbar)
                buttonsFrame.size.height = 0.;
            _toolBarView.frame = buttonsFrame;
            
            CGRect contentFrame = _contentContainer.frame;
            contentFrame.size.width = _scrollableView.bounds.size.width;
            contentFrame.origin.y = [self hasCustomStatusBar] && ([self isLandscape] || newY > [self getStatusBarHeight])
                    ? 0.
                    : CGRectGetMaxY(_statusBarBackgroundView.frame);
            contentFrame.size.height = frame.size.height - buttonsFrame.size.height - contentFrame.origin.y;
            _contentContainer.frame = contentFrame;
            
            CGFloat tableViewY = CGRectGetMaxY(_topHeaderContainerView.frame);
            _tableView.frame = CGRectMake(
                    0.,
                    [self hasCustomHeaderFooter] ? 0 : tableViewY,
                    contentFrame.size.width,
                    [self hasCustomHeaderFooter] ? contentFrame.size.height + self.toolBarView.frame.size.height
                            : contentFrame.size.height - tableViewY
            );

            [UIView animateWithDuration:0.2 animations:^{
                [self onViewHeightChanged:DeviceScreenHeight - _scrollableView.frame.origin.y];
            } completion:nil];
            [self applyCornerRadius:newY > 0];
            return;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            BOOL shouldRefresh = NO;
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if (([self hasInitialState] && (newY - initialPoint.y > self.toolBarView.frame.size.height || fastDownSlide) && _currentState == EOADraggableMenuStateInitial) || (![self hasInitialState] && (newY > DeviceScreenHeight - ([self getToolbarHeight] == 0 ? self.topHeaderContainerView.frame.size.height + [OAUtilities getBottomMargin] : self.toolBarView.frame.size.height))))
            {
                [self hide:YES duration:0.2 onComplete:nil];
                break;
            }
            else if (newY > DeviceScreenHeight - [self initialMenuHeight] + _toolBarView.frame.size.height + _tableView.frame.origin.y && !fastUpSlide && [self hasInitialState])
            {
                shouldRefresh = YES;
                _currentState = EOADraggableMenuStateInitial;
            }
            else if ((newY < fullScreenAnchor || (!slidingDown && _currentState == EOADraggableMenuStateExpanded) || fastUpSlide) && self.supportsFullScreen)
            {
                if (!slidingDown && _currentState == EOADraggableMenuStateExpanded)
                {
                    if (newY > DeviceScreenHeight - self.initialMenuHeight && [self hasInitialState])
                        _currentState = EOADraggableMenuStateInitial;
                    else if (newY > DeviceScreenHeight - self.expandedMenuHeight)
                        _currentState = EOADraggableMenuStateExpanded;
                    else
                        _currentState = EOADraggableMenuStateFullScreen;
                }
                else
                    _currentState = EOADraggableMenuStateFullScreen;
            }
            else if (newY < expandedAnchor || (newY > expandedAnchor && !slidingDown))
            {
                shouldRefresh = YES;
                if (!slidingDown && newY > DeviceScreenHeight - self.initialMenuHeight && [self hasInitialState])
                    _currentState = EOADraggableMenuStateInitial;
                else if (!slidingDown && newY < DeviceScreenHeight - self.expandedMenuHeight)
                    _currentState = EOADraggableMenuStateFullScreen;
                else
                    _currentState = EOADraggableMenuStateExpanded;
            }
            else
            {
                shouldRefresh = YES;
                if (slidingDown && _currentState == EOADraggableMenuStateExpanded && newY < DeviceScreenHeight - self.expandedMenuHeight)
                    _currentState = EOADraggableMenuStateExpanded;
                else
                    _currentState = [self hasInitialState] ? EOADraggableMenuStateInitial : EOADraggableMenuStateExpanded;
            }
            [UIView animateWithDuration:0.2 animations:^{
                [self layoutSubviews];
            } completion:^(BOOL) {
                _isDraggingOnTable = NO;
                _firstStateChanged = YES;
            }];
        }
        default:
        {
            break;
        }
    }
}

- (void) updateView:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.2 animations:^{
            [self layoutSubviews];
        } completion:nil];
    }
    else
    {
        [self layoutSubviews];
    }
}

- (void) goExpanded
{
	if (_currentState != EOADraggableMenuStateExpanded)
		[self goExpanded:YES];
}

- (void) goMinimized
{
	if (_currentState != EOADraggableMenuStateInitial)
		[self goMinimized:YES];
}

- (void) goFullScreen
{
    [self goFullScreen:YES];
}

- (void) goExpanded:(BOOL)animated
{
    _currentState = EOADraggableMenuStateExpanded;
    [self updateView:animated];
}

- (void) goMinimized:(BOOL)animated
{
    _currentState = EOADraggableMenuStateInitial;
    [self updateView:animated];
}

- (void) goFullScreen:(BOOL)animated
{
    _currentState = EOADraggableMenuStateFullScreen;
    [self updateView:animated];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![self stopChangingHeight:touch.view] && ![self isLeftSidePresentation];
}

- (BOOL)stopChangingHeight:(UIView *)view
{
    return NO; //override
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    UIView *otherView = otherGestureRecognizer.view;
    if ([self stopChangingHeight:otherView])
        return NO;

    if (otherView == _tableView)
    {
        if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        {
            UIPanGestureRecognizer *otherPanGestureRecognizer = (UIPanGestureRecognizer *) otherGestureRecognizer;
            CGFloat velocity = [otherPanGestureRecognizer velocityInView:self.view].y;
            BOOL slidingDown = velocity > 0.;
            CGFloat tableContentOffsetY = _tableView.contentOffset.y;
            if (slidingDown && tableContentOffsetY <= 0.)
                return _isDraggingOnTable = YES;
            else
                return NO;
        }
        else
        {
            return NO;
        }
    }
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.shouldScrollInAllModes)
        return;
    
    if (scrollView.contentOffset.y <= 0 || self.contentContainer.frame.origin.y != [self getStatusBarHeight])
        [scrollView setContentOffset:CGPointZero animated:NO];
    
    [self setupModeViewShadowVisibility];
}

#pragma mark - OADraggableViewMethods

- (void)onViewStateChanged:(CGFloat)height
{
    //override
}

- (void)onViewHeightChanged:(CGFloat)height
{
    //override
}

@end
