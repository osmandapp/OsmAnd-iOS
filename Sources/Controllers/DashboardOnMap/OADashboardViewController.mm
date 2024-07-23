//
//  OADashboardViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADashboardViewController.h"
#import "OAAutoObserverProxy.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAObservable.h"
#import "OAAppData.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

const static CGFloat kMapSettingsInitialPosKoeff = 0.35;
const static CGFloat kMapSettingsLandscapeWidth = 320.0;

@interface OADashboardViewController () <OATableViewDelegate>
{
    BOOL isAppearFirstTime;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
}

@property (nonatomic) NSArray* tableData;

@end

@implementation OADashboardViewController
{
    OsmAndAppInstance _app;
    
    UIView *_backgroundView;
    BOOL _showing;
    BOOL _hiding;
    BOOL _rotating;
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
    if (![self.tableView isSliding] && !_showing && !_hiding)
        [self updateLayout:NO];
}

- (CGFloat) calculateTableHeight
{
    [self.tableView layoutIfNeeded];
    return self.tableView.contentSize.height;
}

- (CGFloat) getInitialPosY
{
    BOOL leftSideLayout = [OAUtilities isLandscapeIpadAware];
    CGRect navbarFrame = [self navbarViewFrame];
    CGSize screenSize = [self screenSize];
    return leftSideLayout ? navbarFrame.size.height : screenSize.height * kMapSettingsInitialPosKoeff;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateBackgroundViewLayout];
        _rotating = YES;
        UIView *headerView = self.tableView.tableHeaderView;
        
        CGRect navbarFrame = [self navbarViewFrame];
        headerView.frame = CGRectMake(0, 0, navbarFrame.size.width, [self getInitialPosY]);
        self.tableView.tableHeaderView = headerView;
        [self updateBackgroundViewLayout:self.tableView.contentOffset];
        self.view.frame = [self contentViewFrame];
        _navbarView.frame = navbarFrame;
        _navbarGradientBackgroundView.frame = navbarFrame;
        [self updateNavbarBackground];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _rotating = NO;
        [self updateBackgroundViewLayout];
    }];
}

- (void) updateBackgroundViewLayout
{
    [self updateBackgroundViewLayout:self.tableView.contentOffset];
}

- (void) updateBackgroundViewLayout:(CGPoint)contentOffset
{
    CGRect navbarFrame = [self navbarViewFrame];
    CGRect contentFrame = [self contentViewFrame];
    if ([OAUtilities isLandscapeIpadAware])
        _backgroundView.frame = CGRectMake(0, _rotating ? navbarFrame.size.height : 0, contentFrame.size.width, contentFrame.size.height);
    else
        _backgroundView.frame = CGRectMake(0, MAX(0, [self getInitialPosY] - contentOffset.y), contentFrame.size.width, contentFrame.size.height);
}

- (void)updateLayout:(BOOL)adjustOffset
{
    BOOL leftSideLayout = [OAUtilities isLandscapeIpadAware];
    if (!self.showFull && leftSideLayout)
        self.showFull = YES;
    
    CGPoint newOffset;
    if (_showFull && !leftSideLayout)
        newOffset = {0, [self getInitialPosY]};
    else
        newOffset = {0, 0};
    
    if (adjustOffset)
        self.tableView.contentOffset = newOffset;
}

- (CGSize)screenSize
{
    return CGSizeMake(DeviceScreenWidth, DeviceScreenHeight);
}

- (CGFloat) getViewWidthForPad
{
    return [OAUtilities isLandscape] ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad;
}

- (CGRect)contentViewFrame
{
    CGSize screenSize = [self screenSize];
    CGFloat frameWidth = [OAUtilities isIPad] ? [self getViewWidthForPad] : kMapSettingsLandscapeWidth;
    return CGRectMake(0.0, 0.0, [OAUtilities isLandscapeIpadAware] ? frameWidth + [OAUtilities getLeftMargin] : screenSize.width, screenSize.height);
}

- (CGRect)navbarViewFrame
{
    CGSize screenSize = [self screenSize];
    CGFloat navBarHeight = [OAUtilities getStatusBarHeight];
    navBarHeight = navBarHeight == inCallStatusBarHeight ? navBarHeight / 2 : navBarHeight;
    if (![OAUtilities isLandscapeIpadAware])
    {
        return CGRectMake(0.0, 0.0, screenSize.width, kOADashboardNavbarHeight + navBarHeight);
    }
    else
    {
        CGFloat frameWidth = [OAUtilities isIPad] ? [self getViewWidthForPad] : kMapSettingsLandscapeWidth;
        return CGRectMake(0.0, 0.0, frameWidth + [OAUtilities getLeftMargin], kOADashboardNavbarHeight + navBarHeight);
    }
}

- (void) show:(UIViewController *)rootViewController parentViewController:(OADashboardViewController *)parentViewController animated:(BOOL)animated;
{
    _showing = YES;
    if (parentViewController)
        _topControlsVisible = parentViewController.topControlsVisible;
    else
        _topControlsVisible = [[OARootViewController instance].mapPanel isTopControlsVisible];

    [[OARootViewController instance].mapPanel.hudViewController hideWeatherToolbarIfNeeded];

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
    if ([self isMainScreen] && [OAUtilities isPortrait] && [OAUtilities isIPhone])
    {
        frame.origin.y = DeviceScreenHeight + 10.0;
        navbarFrame.origin.y = -navbarFrame.size.height;
    }
    else
    {
        frame.origin.x = -10.0 - frame.size.width;
        //frame.origin.y += 20.0;
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
        {
            [[OARootViewController instance].mapPanel targetUpdateControlsLayout:YES
                                                            customStatusBarStyle:UIStatusBarStyleLightContent];
        }
    }
    
    self.navbarView.frame = navbarFrame;
    [rootViewController.view addSubview:self.navbarView];

    [self updateNavbarBackground];

    if (animated)
    {
        [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (_parentVC)
            {
                _parentVC.view.alpha = 0.0;
                _parentVC.view.frame = parentFrame;
                _parentVC.navbarView.alpha = 0.0;
                _parentVC.navbarView.frame = parentNavbarFrame;
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
            _showing = NO;
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
        _showing = NO;
    }
}

- (void) hide:(BOOL)hideAll animated:(BOOL)animated
{
    [self hide:hideAll animated:animated duration:.3];
}

- (void) hide:(BOOL)hideAll animated:(BOOL)animated duration:(CGFloat)duration
{
    _hiding = YES;
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
        [[OARootViewController instance].mapPanel targetUpdateControlsLayout:NO customStatusBarStyle:UIStatusBarStyleDefault];
    
    if (animated)
    {
        [UIView animateWithDuration:duration animations:^{
            
            CGRect navbarFrame;
            CGRect contentFrame;

            if ([OAUtilities isPortrait] && [OAUtilities isIPhone])
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
                _parentVC.view.alpha = 1.0;
                _parentVC.view.frame = parentFrame;
                _parentVC.navbarView.alpha = 1.0;
                _parentVC.navbarView.frame = parentNavbarFrame;
            }
            
        } completion:^(BOOL finished) {
            
            [self deleteParentVC:hideAll];
            _hiding = NO;
            [[OARootViewController instance].mapPanel recreateControls];
        }];
    }
    else
    {
        if (_parentVC && !hideAll)
        {
            _parentVC.view.alpha = 1.0;
            _parentVC.view.frame = parentFrame;
            _parentVC.navbarView.alpha = 1.0;
            _parentVC.navbarView.frame = parentNavbarFrame;
        }
        
        [self deleteParentVC:hideAll];
        _hiding = NO;
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
    [super applyLocalization];
    
    [_okButton setTitle:OALocalizedString(@"shared_string_ok") forState:UIControlStateNormal];
}

- (void) addAccessibilityLabels
{
    self.backButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
}

- (void) updateNavbarBackground
{
    UIView *navbarGradientBackgroundView = [self getNavbarGradientBackgroundView];
    
    if ([OAUtilities isPortrait] && [OAUtilities isIPhone])
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
    
    [self updateNavbarBackground];

    [self.backButton setImage:[UIImage imageNamed:@"ic_navbar_chevron"].imageFlippedForRightToLeftLayoutDirection forState:UIControlStateNormal];

    _okButton.hidden = YES;
    
    CGRect navbarFrame = [self navbarViewFrame];
    [self.navbarView addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:0. padding:0.];

    self.tableView = (OATableView *)self.view;
    self.tableView.oaDelegate = self;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(navbarFrame.size.height - [OAUtilities getStatusBarHeight], 0, 0, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    
    UIView *headerView = [[UIView alloc] initWithFrame:{ 0, 0, navbarFrame.size.width, [self getInitialPosY] }];
    headerView.backgroundColor = UIColor.clearColor;
    headerView.opaque = NO;
    self.tableView.tableHeaderView = headerView;
    self.tableView.sectionFooterHeight = 0.01;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    self.tableView.tableFooterView = footerView;
    [self.tableView registerClass:[FreeBackupBannerCell class] forCellReuseIdentifier:[FreeBackupBannerCell getCellIdentifier]];
    _backgroundView = [[UIView alloc] initWithFrame:{0, -1, 1, 1}];
    _backgroundView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    _backgroundView.autoresizingMask = UIViewAutoresizingNone;
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColor.clearColor;
    [view addSubview:_backgroundView];
    self.tableView.backgroundView = view;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.clipsToBounds = NO;
    [self updateBackgroundViewLayout:{0, 0}];

    //self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.tableView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    
    [self setupView];
    
    [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.view.layer setShadowOpacity:0.3];
    [self.view.layer setShadowRadius:3.0];
    [self.view.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    [self.navbarBackgroundView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.navbarBackgroundView.layer setShadowOpacity:0.3];
    [self.navbarBackgroundView.layer setShadowRadius:3.0];
    [self.navbarBackgroundView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    [self updateLayout:YES];

    self.okButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([screenObj respondsToSelector:@selector(initView)])
        [screenObj initView];

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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self.navbarView addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:0. padding:0.];
}

- (void)onLeftNavbarButtonPressed
{
    if ([screenObj respondsToSelector:@selector(backButtonPressed)] && ![screenObj backButtonPressed])
        return;

    if ([self isMainScreen])
        [self closeDashboard];
    else
        [self hide:NO animated:YES];
}

- (IBAction) okButtonClicked:(id)sender
{
    if ([screenObj respondsToSelector:@selector(okButtonPressed)] && ![screenObj okButtonPressed])
        return;

    [self onLeftNavbarButtonPressed];
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
    
    self.view.frame = [self contentViewFrame];
}

- (void) setupView
{
    if (!self.tableView.dataSource)
        self.tableView.dataSource = screenObj;
    if (!self.tableView.delegate)
        self.tableView.delegate = screenObj;
    if (!self.tableView.tableFooterView)
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:{0, 0, 0, 0.01}];
    
    [screenObj setupView];
    
    self.titleView.text = screenObj.title;
}

- (void) closeDashboard
{
    [[OARootViewController instance].mapPanel closeDashboard];
}

- (CGFloat)getNavbarAlpha
{
    CGFloat alpha = self.view.alpha;
    if (alpha > 0 && ![OAUtilities isLandscapeIpadAware])
    {
        CGFloat initialPosY = [self getInitialPosY];
        CGRect navbarFrame = [self navbarViewFrame];
        CGFloat a = initialPosY - [OAUtilities getStatusBarHeight];
        CGFloat b = initialPosY - navbarFrame.size.height;
        CGFloat c = self.tableView.contentOffset.y;
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

#pragma mark - OATableViewDelegate

- (void) tableViewWillEndDragging:(OATableView *)tableView withVelocity:(CGPoint)velocity withStartOffset:(CGPoint)startOffset
{
    CGFloat offsetY = tableView.contentOffset.y;
    BOOL slidingDown = velocity.y > 500 || offsetY < -50;
    BOOL landscape = [OAUtilities isLandscapeIpadAware];
    
    if (slidingDown && offsetY < 0 && !landscape)
        [self closeDashboard];
}

- (void) tableViewContentOffsetChanged:(OATableView *)tableView contentOffset:(CGPoint)contentOffset
{
    if (!_rotating && !_showing && !_hiding)
    {
        [self updateBackgroundViewLayout:contentOffset];
        [self updateNavbarBackground];
    }
}

- (BOOL) tableViewScrollAllowed:(OATableView *)tableView
{
    return YES;
}

@end
