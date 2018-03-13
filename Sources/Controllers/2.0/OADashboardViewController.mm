//
//  OADashboardViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADashboardViewController.h"

#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"

#import "Localization.h"
#import "OAUtilities.h"

#import <CoreLocation/CoreLocation.h>

@interface OADashboardViewController () <UIScrollViewDelegate, OAScrollViewDelegate>
{    
    BOOL isAppearFirstTime;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
}

@property (nonatomic) NSArray* tableData;

@end

@implementation OADashboardViewController
{
    OsmAndAppInstance _app;
    
    OAScrollView *_containerView;
    
    CGFloat _headerY;
    CGFloat _headerHeight;
    CGFloat _headerOffset;
    CGFloat _fullHeight;
    CGFloat _fullOffset;
    CGFloat _startDragOffsetY;
}

@synthesize screenObj;

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OADashboardViewController" bundle:nil];
}

- (instancetype) initWithScreenType:(NSInteger)screenType;
{
    self = [super init];
    if (self)
    {
        self.screenType = screenType;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithScreenType:(NSInteger)screenType param:(id)param;
{
    self = [super init];
    if (self)
    {
        self.screenType = screenType;
        self.customParam = param;
        [self commonInit];
    }
    return self;
}

- (BOOL) isMainScreen
{
    return YES;
}

- (void) viewWillLayoutSubviews
{
    if (![_containerView isSliding])
        [self updateLayout:[[UIApplication sharedApplication] statusBarOrientation] adjustOffset:NO];
}

- (CGFloat) calculateTableHeight
{
    return _tableView.contentSize.height;
}

- (BOOL) isLeftSideLayout:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (void) updateLayout:(UIInterfaceOrientation)interfaceOrientation adjustOffset:(BOOL)adjustOffset
{
    BOOL leftSideLayout = [self isLeftSideLayout:interfaceOrientation];
    if (!self.showFull && leftSideLayout)
        self.showFull = YES;

    CGRect navbarFrame = [self navbarViewFrame:interfaceOrientation];
    CGFloat width = navbarFrame.size.width;

    _navbarView.frame = navbarFrame;
    _navbarGradientBackgroundView.frame = navbarFrame;
    
    [self updateNavbarBackground:interfaceOrientation];
    
    CGFloat contentViewHeight = [self calculateTableHeight];

    CGRect f = _tableView.frame;
    f.origin.y = leftSideLayout ? navbarFrame.size.height : DeviceScreenHeight - kMapSettingsContentHeight;
    f.size.height = MAX(leftSideLayout ? DeviceScreenHeight - navbarFrame.size.height : kMapSettingsContentHeight, contentViewHeight);
    _tableView.frame = f;
    
    _headerY = _tableView.frame.origin.y;
    _headerOffset = 0;
    if (leftSideLayout)
    {
        _headerHeight = f.size.height;
        _fullHeight = f.size.height;
    }
    else
    {
        _headerHeight = kMapSettingsContentHeight;
        _fullHeight = _headerHeight + contentViewHeight - kMapSettingsContentHeight;
    }
    _fullOffset = _headerY - navbarFrame.size.height;
    
    CGFloat contentHeight = _headerY + _fullHeight;
    
    if (leftSideLayout)
    {
        _topOverscrollView.frame = CGRectMake(0.0, _headerY - 1000.0, width, 1000.0);
        _topOverscrollView.hidden = NO;
    }
    else
    {
        _topOverscrollView.hidden = YES;
    }
    _bottomOverscrollView.frame = CGRectMake(0, contentHeight, width, 1000.0);
    
    _containerView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    _containerView.contentSize = CGSizeMake(width, contentHeight);
    
    CGPoint newOffset;
    if (_showFull)
        newOffset = {0, _fullOffset};
    else
        newOffset = {0, _headerOffset};
    
    if (adjustOffset)
        _containerView.contentOffset = newOffset;
}


- (CGRect) contentViewFrame:(UIInterfaceOrientation)interfaceOrientation
{
    if (![self isLeftSideLayout:interfaceOrientation])
    {
        return CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight);
    }
    else
    {
        return CGRectMake(0.0, 0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? kMapSettingsLandscapeWidth : 320.0, DeviceScreenHeight);
    }
}

- (CGRect) contentViewFrame
{
    return [self contentViewFrame:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (CGRect) navbarViewFrame:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        return CGRectMake(0.0, 0.0, DeviceScreenWidth, kOADashboardNavbarHeight);
    }
    else
    {
        return CGRectMake(0.0, 0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? kMapSettingsLandscapeWidth : 320.0, kOADashboardNavbarHeight);
    }
}

- (CGRect) navbarViewFrame
{
    return [self navbarViewFrame:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void) show:(UIViewController *)rootViewController parentViewController:(OADashboardViewController *)parentViewController animated:(BOOL)animated;
{
    if (parentViewController)
        _topControlsVisible = parentViewController.topControlsVisible;
    else
        _topControlsVisible = [[OARootViewController instance].mapPanel isTopControlsVisible];

    self.parentVC = parentViewController;
    self.showFull = parentViewController.showFull;
    
    [rootViewController addChildViewController:self];
    [self willMoveToParentViewController:rootViewController];
    
    CGRect parentFrame;
    CGRect parentNavbarFrame;
    if (_parentVC)
    {
        parentFrame = CGRectOffset(_parentVC.view.frame, -50.0, 0.0);
        parentNavbarFrame = CGRectOffset(_parentVC.navbarView.frame, -50.0, 0.0);
    }
    
    CGRect frame = [self contentViewFrame];
    CGRect navbarFrame = [self navbarViewFrame];
    if ([self isMainScreen] && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        frame.origin.y = DeviceScreenHeight + 10.0;
        navbarFrame.origin.y = -navbarFrame.size.height;
    }
    else
    {
        frame.origin.x = -10.0 - frame.size.width;
        frame.origin.y += 20.0;
        navbarFrame.origin.x = -10.0 - navbarFrame.size.width;
    }
    
    self.view.frame = frame;
    if (!_parentVC)
        [rootViewController.view addSubview:self.view];
    else
        [rootViewController.view insertSubview:self.view aboveSubview:_parentVC.view];
    
    if (!_parentVC)
    {
        _navbarGradientBackgroundView.frame = navbarFrame;
        [rootViewController.view addSubview:self.navbarGradientBackgroundView];
        
        if (_topControlsVisible)
            [[OARootViewController instance].mapPanel setTopControlsVisible:NO];
    }
    
    self.navbarView.frame = navbarFrame;
    [rootViewController.view addSubview:self.navbarView];

    [self updateNavbarBackground:[[UIApplication sharedApplication] statusBarOrientation]];

    if (animated)
    {
        [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (_parentVC)
            {
                _parentVC.view.frame = parentFrame;
                _parentVC.view.alpha = 0.0;
                _parentVC.navbarView.frame = parentNavbarFrame;
                _parentVC.navbarView.alpha = 0.0;
            }
            else
            {
                _navbarGradientBackgroundView.frame = [self navbarViewFrame];
            }
            
            _navbarView.frame = [self navbarViewFrame];
            self.view.frame = [self contentViewFrame];
            
        } completion:^(BOOL finished) {
            [self didMoveToParentViewController:rootViewController];
            if (_parentVC)
            {
                _parentVC.view.hidden = YES;
                _parentVC.navbarView.hidden = YES;
            }
        }];
    }
    else
    {
        _navbarView.frame = [self navbarViewFrame];
        self.view.frame = [self contentViewFrame];
        
        [self didMoveToParentViewController:rootViewController];
        if (_parentVC)
        {
            _parentVC.view.hidden = YES;
            _parentVC.navbarView.hidden = YES;
        }
        else
        {
            _navbarGradientBackgroundView.frame = [self navbarViewFrame];
        }
    }
}

- (void) hide:(BOOL)hideAll animated:(BOOL)animated
{
    [self hide:hideAll animated:animated duration:.3];
}

- (void) hide:(BOOL)hideAll animated:(BOOL)animated duration:(CGFloat)duration
{
    CGRect parentFrame;
    CGRect parentNavbarFrame;
    if (_parentVC)
    {
        parentFrame = CGRectOffset(_parentVC.view.frame, -_parentVC.view.frame.origin.x, 0.0);
        parentNavbarFrame = CGRectOffset(_parentVC.navbarView.frame, -_parentVC.navbarView.frame.origin.x, 0.0);
        _parentVC.view.alpha = 0.0;
        _parentVC.view.hidden = NO;
        _parentVC.navbarView.alpha = 0.0;
        _parentVC.navbarView.hidden = NO;
    }
    
    if (_parentVC && !hideAll)
        [_parentVC setupView];
    
    if (_topControlsVisible && (!_parentVC || hideAll))
        [[OARootViewController instance].mapPanel setTopControlsVisible:YES];
    
    if (animated)
    {
        [UIView animateWithDuration:duration animations:^{
            
            CGRect navbarFrame;
            CGRect contentFrame;
            
            if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            {
                if ([self isMainScreen] || hideAll)
                {
                    navbarFrame = CGRectMake(0.0, -_navbarView.frame.size.height, _navbarView.frame.size.width, _navbarView.frame.size.height);
                    contentFrame = CGRectMake(0.0, DeviceScreenHeight + 10.0, self.view.bounds.size.width, self.view.bounds.size.height);
                }
                else
                {
                    navbarFrame = CGRectMake(DeviceScreenWidth + 10.0, _navbarView.frame.origin.y, _navbarView.frame.size.width, _navbarView.frame.size.height);
                    contentFrame = CGRectMake(DeviceScreenWidth + 10.0, self.view.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
                }
            }
            else
            {
                navbarFrame = CGRectMake(-10.0 - _navbarView.bounds.size.width, _navbarView.frame.origin.y, _navbarView.frame.size.width, _navbarView.frame.size.height);
                contentFrame = CGRectMake(-10.0 - self.view.bounds.size.width, self.view.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
            }
            _navbarView.frame = navbarFrame;
            self.view.frame = contentFrame;
            if (!_parentVC || hideAll)
            {
                UIView *navbarGradientBackgroundView = [self getNavbarGradientBackgroundView];
                if (navbarGradientBackgroundView)
                    navbarGradientBackgroundView.frame = navbarFrame;
            }
            
            if (_parentVC && !hideAll)
            {
                _parentVC.view.frame = parentFrame;
                _parentVC.view.alpha = 1.0;
                _parentVC.navbarView.frame = parentNavbarFrame;
                _parentVC.navbarView.alpha = 1.0;
            }
            
        } completion:^(BOOL finished) {
            
            [self deleteParentVC:hideAll];
            
        }];
    }
    else
    {
        if (_parentVC && !hideAll)
        {
            _parentVC.view.frame = parentFrame;
            _parentVC.view.alpha = 1.0;
            _parentVC.navbarView.frame = parentNavbarFrame;
            _parentVC.navbarView.alpha = 1.0;
        }
        
        [self deleteParentVC:hideAll];
    }
}

- (void) deleteParentVC:(BOOL)deleteAll
{
    if (_parentVC)
    {
        if (deleteAll)
            [_parentVC deleteParentVC:YES];
        
        self.parentVC = nil;
    }
    
    [self removeFromParentViewController];
    [self.navbarView removeFromSuperview];
    [self.view removeFromSuperview];
    
    if (!_parentVC)
        [self.navbarGradientBackgroundView removeFromSuperview];
}

- (UIView *) getNavbarGradientBackgroundView
{
    OADashboardViewController *topVC = self;
    OADashboardViewController *pVC = _parentVC;
    while (pVC)
    {
        topVC = pVC;
        pVC = pVC.parentVC;
    }
    if (topVC)
        return topVC.navbarGradientBackgroundView;
    else
        return nil;
}

- (void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) updateNavbarBackground:(UIInterfaceOrientation)interfaceOrientation
{
    UIView *navbarGradientBackgroundView = [self getNavbarGradientBackgroundView];
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGFloat alpha = [self getNavbarAlpha];
        _navbarBackgroundView.alpha = alpha;
        if (navbarGradientBackgroundView)
            navbarGradientBackgroundView.alpha = 1.0 - alpha;
    }
    else
    {
        _navbarBackgroundView.alpha = 1.0;
        if (navbarGradientBackgroundView)
            navbarGradientBackgroundView.alpha = 0.0;
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _containerView = (OAScrollView *)self.view;
    
    [self updateNavbarBackground:[[UIApplication sharedApplication] statusBarOrientation]];
    
    _containerView.delegate = self;
    _containerView.oaDelegate = self;
    _containerView.alwaysBounceVertical = YES;
    _containerView.showsVerticalScrollIndicator = YES;
    _containerView.decelerationRate = UIScrollViewDecelerationRateNormal;
    _containerView.scrollIndicatorInsets = UIEdgeInsetsMake(kOADashboardNavbarHeight - 20, 0, 0, 0);

    //self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.tableView.separatorColor = UIColorFromRGB(0xf2f2f2);
    //UIView *view = [[UIView alloc] init];
    //view.backgroundColor = UIColorFromRGB(0xffffff);
    //self.tableView.backgroundView = view;
    _topOverscrollView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    _topOverscrollView.hidden = YES;
    _bottomOverscrollView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    self.tableView.scrollEnabled = NO;
    
    [self setupView];
    
    [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.view.layer setShadowOpacity:0.3];
    [self.view.layer setShadowRadius:3.0];
    [self.view.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    [self.navbarBackgroundView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.navbarBackgroundView.layer setShadowOpacity:0.3];
    [self.navbarBackgroundView.layer setShadowRadius:3.0];
    [self.navbarBackgroundView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    [self updateLayout:[[UIApplication sharedApplication] statusBarOrientation] adjustOffset:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (isAppearFirstTime)
        isAppearFirstTime = NO;
    else
        [screenObj setupView];
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_lastMapSourceChangeObserver)
    {
        [_lastMapSourceChangeObserver detach];
        _lastMapSourceChangeObserver = nil;
    }
    
    if ([screenObj respondsToSelector:@selector(deinitView)])
        [screenObj deinitView];
}

- (IBAction) backButtonClicked:(id)sender
{
    if ([self isMainScreen])
        [self closeDashboard];
    else
        [self hide:NO animated:YES];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) commonInit
{
    isAppearFirstTime = YES;
    _app = [OsmAndApp instance];
    
    _startDragOffsetY = 0;
    self.view.frame = [self contentViewFrame];
}

- (void) setupView
{
    if (!self.tableView.dataSource)
        self.tableView.dataSource = screenObj;
    if (!self.tableView.delegate)
        self.tableView.delegate = screenObj;
    if (!self.tableView.tableFooterView)
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [screenObj setupView];
    
    self.titleView.text = screenObj.title;
}

- (void) closeDashboard
{
    [[OARootViewController instance].mapPanel closeDashboard];
}

- (CGFloat) getNavbarAlpha
{
    CGFloat alpha = 1.0;
    if (![self isLeftSideLayout:[[UIApplication sharedApplication] statusBarOrientation]])
    {
        CGFloat a = _headerY - 20;
        CGFloat b = _headerY - kOADashboardNavbarHeight;
        CGFloat c = _containerView.contentOffset.y;
        alpha = (c - b) / (a - b);
        if (alpha < 0)
            alpha = 0.0;
        if (alpha > 1)
            alpha = 1.0;
    }
    return alpha;
}

- (void) onLastMapSourceChanged
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupView];
        [self.view setNeedsLayout];
    });
}

#pragma mark - Orientation

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //BOOL slidingUp = velocity.y > 0;
    BOOL slidingDown = velocity.y < -0.3;
    
    BOOL needCloseMenu = NO;
    
    CGFloat offsetY = targetContentOffset->y;
    
    if (slidingDown && offsetY == 0 && _startDragOffsetY == 0)
        needCloseMenu = ![self isLeftSideLayout:[[UIApplication sharedApplication] statusBarOrientation]];
    
    if (needCloseMenu)
        [self closeDashboard];
    
    _startDragOffsetY = offsetY;
}

#pragma mark - OAScrollViewDelegate

- (void) onContentOffsetChanged:(CGPoint)contentOffset
{
    [self updateNavbarBackground:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (BOOL) isScrollAllowed
{
    return YES;
}

@end
