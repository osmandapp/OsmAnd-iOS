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

@interface OADashboardViewController ()
{    
    BOOL isAppearFirstTime;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
}

@property (nonatomic) NSArray* tableData;

@end

@implementation OADashboardViewController
{
    OsmAndAppInstance _app;

    BOOL _sliding;
    CGPoint _topViewStartSlidingPos;
    
    UIPanGestureRecognizer *_panGesture;
    CALayer *_horizontalLine;
}

@synthesize screenObj;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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

- (void) moveContent:(UIPanGestureRecognizer *)gesture
{
    if ([self isLeftSideLayout:[[UIApplication sharedApplication] statusBarOrientation]])
        return;
    
    CGPoint translatedPoint = [gesture translationInView:[OARootViewController instance].mapPanel.mapViewController.view];
    CGPoint translatedVelocity = [gesture velocityInView:[OARootViewController instance].mapPanel.mapViewController.view];
    
    CGFloat h = kMapSettingsContentHeight;
    
    if ([gesture state] == UIGestureRecognizerStateBegan)
    {
        _sliding = YES;
        _topViewStartSlidingPos = self.view.frame.origin;
    }
    
    if ([gesture state] == UIGestureRecognizerStateChanged)
    {
        CGRect f = self.view.frame;
        f.origin.y = _topViewStartSlidingPos.y + translatedPoint.y;
        f.size.height = DeviceScreenHeight - f.origin.y;
        if (f.size.height < 0)
            f.size.height = 0;
        
        self.view.frame = f;
    }
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed)
    {
        if (translatedVelocity.y < 200.0)
            //if (self.frame.origin.y < (DeviceScreenHeight - h - 20.0))
        {
            CGRect frame = self.view.frame;
            CGFloat fullHeight = DeviceScreenHeight - 64.0;
            BOOL goFull = !self.showFull && frame.size.height < fullHeight;
            self.showFull = YES;
            frame.size.height = fullHeight;
            frame.origin.y = DeviceScreenHeight - fullHeight;
            
            
            [UIView animateWithDuration:.3 animations:^{
                
                self.view.frame = frame;
                
            } completion:^(BOOL finished) {
                if (!goFull)
                {
                    _sliding = NO;
                    [self.view setNeedsLayout];
                }
                
            }];
            
            if (goFull)
            {
                _sliding = NO;
                [self.view setNeedsLayout];
            }
        }
        else
        {
            if ((self.showFull || translatedVelocity.y < 200.0) && self.view.frame.origin.y < kMapSettingsContentHeight * 0.8)
            {
                self.showFull = NO;
                
                CGRect frame = self.view.frame;
                frame.origin.y = DeviceScreenHeight - h;
                frame.size.height = h;
                
                CGFloat delta = self.view.frame.origin.y - frame.origin.y;
                CGFloat duration = (delta > 0.0 ? .2 : fabs(delta / (translatedVelocity.y * 0.5)));
                if (duration > .2)
                    duration = .2;
                if (duration < .1)
                    duration = .1;
                
                
                [UIView animateWithDuration:duration animations:^{
                    
                    self.view.frame = frame;
                    
                } completion:^(BOOL finished) {
                    _sliding = NO;
                    [self.view setNeedsLayout];
                }];
                
            }
            else
            {
                CGFloat delta = self.view.frame.origin.y - DeviceScreenHeight;
                CGFloat duration = (delta > 0.0 ? .3 : fabs(delta / translatedVelocity.y));
                if (duration > .3)
                    duration = .3;
                
                [[OARootViewController instance].mapPanel closeDashboardWithDuration:duration];
            }
        }
    }
}

- (void)viewWillLayoutSubviews
{
    if (!_sliding)
        [self updateLayout:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (BOOL)isLeftSideLayout:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    if (!self.showFull && [self isLeftSideLayout:interfaceOrientation])
        self.showFull = YES;
    
    self.view.frame = [self contentViewFrame:interfaceOrientation];
    _navbarView.frame = [self navbarViewFrame:interfaceOrientation];
    _navbarBackgroundView.frame = [self navbarViewFrame:interfaceOrientation];
    
    [self updateNavbarBackground:interfaceOrientation];
    
    _horizontalLine.frame = CGRectMake(0.0, _tableView.frame.origin.y, self.view.frame.size.width, 0.5);
    
    if ([self isLeftSideLayout:interfaceOrientation])
    {
        _pickerImg.hidden = YES;
        _pickerView.hidden = YES;
        _horizontalLine.hidden = YES;
        _containerView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        _tableView.frame = _containerView.frame;
    }
    else
    {
        _pickerImg.hidden = NO;
        _pickerView.hidden = NO;
        _horizontalLine.hidden = NO;
        _containerView.frame = CGRectMake(0.0, 16.0, self.view.frame.size.width, self.view.frame.size.height - 16.0);
        _tableView.frame = CGRectMake(0.0, 8.0, _containerView.frame.size.width, _containerView.frame.size.height - 8.0);
    }
}


-(CGRect)contentViewFrame:(UIInterfaceOrientation)interfaceOrientation
{
    if (![self isLeftSideLayout:interfaceOrientation])
    {
        if (self.showFull)
            return CGRectMake(0.0, 64.0, DeviceScreenWidth, DeviceScreenHeight - 64.0);
        else
            return CGRectMake(0.0, DeviceScreenHeight - kMapSettingsContentHeight, DeviceScreenWidth, kMapSettingsContentHeight);
    }
    else
    {
        return CGRectMake(0.0, 64.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? kMapSettingsLandscapeWidth : 320.0, DeviceScreenHeight - 64.0);
    }
}

-(CGRect)contentViewFrame
{
    return [self contentViewFrame:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(CGRect)navbarViewFrame:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        return CGRectMake(0.0, 0.0, DeviceScreenWidth, 64.0);
    }
    else
    {
        return CGRectMake(0.0, 0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? kMapSettingsLandscapeWidth : 320.0, 64.0);
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
        navbarFrame.origin.x = -10.0 - navbarFrame.size.width;
    }
    
    self.view.frame = frame;
    if (!_parentVC)
        [rootViewController.view addSubview:self.view];
    else
        [rootViewController.view insertSubview:self.view aboveSubview:_parentVC.view];
    
    if (!_parentVC)
    {
        _navbarBackgroundView.frame = navbarFrame;
        _navbarBackgroundView.hidden = NO;
        [rootViewController.view addSubview:self.navbarBackgroundView];
        
        if (_topControlsVisible)
            [[OARootViewController instance].mapPanel setTopControlsVisible:NO];
    }
    
    self.navbarView.frame = navbarFrame;
    [rootViewController.view addSubview:self.navbarView];
    
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
                _navbarBackgroundView.frame = [self navbarViewFrame];
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
            _navbarBackgroundView.frame = [self navbarViewFrame];
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
                OADashboardViewController *topVC = self;
                OADashboardViewController *pVC = _parentVC;
                while (pVC)
                {
                    topVC = pVC;
                    pVC = pVC.parentVC;
                }
                topVC.navbarBackgroundView.frame = navbarFrame;
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
        [self.navbarBackgroundView removeFromSuperview];
}

- (void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) updateNavbarBackground:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        _navbarBackgroundView.backgroundColor = [UIColor clearColor];
        _navbarBackgroundImg.hidden = NO;
    }
    else
    {
        _navbarBackgroundView.backgroundColor = UIColorFromRGB(0xFF8F00);
        _navbarBackgroundImg.hidden = YES;
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    [self.containerView.layer addSublayer:_horizontalLine];
    
    _navbarBackgroundView.hidden = YES;
    [self updateNavbarBackground:[[UIApplication sharedApplication] statusBarOrientation]];
    
    [self setupView];
    
    [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.view.layer setShadowOpacity:0.3];
    [self.view.layer setShadowRadius:3.0];
    [self.view.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    [self updateLayout:[[UIApplication sharedApplication] statusBarOrientation]];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveContent:)];
    [self.pickerView addGestureRecognizer:_panGesture];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (isAppearFirstTime)
        isAppearFirstTime = NO;
    else
        [screenObj setupView];
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([screenObj respondsToSelector:@selector(deinitView)])
        [screenObj deinitView];
}

-(IBAction) backButtonClicked:(id)sender
{
    if (_lastMapSourceChangeObserver)
    {
        [_lastMapSourceChangeObserver detach];
        _lastMapSourceChangeObserver = nil;
    }
    
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
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];
        
    self.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight);
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

- (void) onLastMapSourceChanged
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}



@end
