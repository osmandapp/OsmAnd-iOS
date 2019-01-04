//
//  OABottomSheetViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"

#import "OAMapViewController.h"
#import "OARootViewController.h"

#import "Localization.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"

#define kOABottomSheetWidth 320.0

@interface OABottomSheetViewStack : NSObject

@property (nonatomic) NSMutableArray<OABottomSheetViewController *> *bottomSheetViews;

+ (OABottomSheetViewStack *) sharedInstance;

- (void) push:(OABottomSheetViewController *)bottomSheetView;
- (void) pop:(OABottomSheetViewController *)bottomSheetView;

@end

@interface OABottomSheetViewController () <OATableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIWindow *bottomSheetWindow;
@property (nonatomic) UITapGestureRecognizer *tap;
@property (nonatomic) UITapGestureRecognizer *tapContent;

@property (nonatomic) NSArray* tableData;

@end

@implementation OABottomSheetViewController
{
    OsmAndAppInstance _app;
    
    BOOL _appearFirstTime;
    UIView *_tableBackgroundView;
    BOOL _showing;
    BOOL _hiding;
    BOOL _rotating;
}

@synthesize screenObj;

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OABottomSheetViewController" bundle:nil];
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithParam:(id)param
{
    self = [super init];
    if (self)
    {
        _customParam = param;
        [self commonInit];
    }
    return self;
}

- (CGFloat) calculateTableHeight
{
    [self.tableView layoutIfNeeded];
    return self.tableView.contentSize.height;
}

- (BOOL) isLandscape:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _rotating = YES;
        [self applyCorrectSizes];
        [self adjustViewHeight];
        [self updateBackgroundViewLayout];
        [self updateTableHeaderView:CurrentInterfaceOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _rotating = NO;
    }];
}

- (void) updateBackgroundViewLayout
{
    [self updateBackgroundViewLayout:CurrentInterfaceOrientation contentOffset:self.tableView.contentOffset];
}

- (void) updateBackgroundViewLayout:(UIInterfaceOrientation)interfaceOrientation contentOffset:(CGPoint)contentOffset
{
    CGRect contentFrame = [self contentViewFrame:interfaceOrientation];
    if (_tableView.tableHeaderView)
    {
        _tableBackgroundView.frame = CGRectMake(0, MAX(contentFrame.origin.y, _tableView.tableHeaderView.frame.size.height - contentOffset.y), contentFrame.size.width, contentFrame.size.height);
    }
    else
    {
        _tableBackgroundView.frame = CGRectMake(0, 0, contentFrame.size.width, contentFrame.size.height);
    }
}

- (CGRect) screenFrame:(UIInterfaceOrientation)interfaceOrientation
{
    //return [self frameForOrientation];
    CGSize size = [self screenSize:interfaceOrientation];
    return CGRectMake(0, 0, size.width, size.height);
}

- (CGSize) screenSize:(UIInterfaceOrientation)interfaceOrientation
{
    //return [self frameForOrientation].size;
    
    UIInterfaceOrientation currentInterfaceOrientation = CurrentInterfaceOrientation;
    BOOL orientationsEqual = UIInterfaceOrientationIsPortrait(currentInterfaceOrientation) == UIInterfaceOrientationIsPortrait(interfaceOrientation) || UIInterfaceOrientationIsLandscape(currentInterfaceOrientation) == UIInterfaceOrientationIsLandscape(interfaceOrientation);
    if (orientationsEqual)
        return CGSizeMake(DeviceScreenWidth, DeviceScreenHeight);
    else
        return CGSizeMake(DeviceScreenHeight, DeviceScreenWidth);
    
}

- (CGRect) contentViewFrame:(UIInterfaceOrientation)interfaceOrientation
{
    CGSize screenSize = [self screenSize:interfaceOrientation];
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if ([self isLandscape:interfaceOrientation])
        return CGRectMake(screenSize.width / 2 - kOABottomSheetWidth / 2, 0.0, kOABottomSheetWidth, screenSize.height - bottomMargin);
    else
        return CGRectMake(0.0, 0.0, screenSize.width, screenSize.height - bottomMargin);
}

- (CGRect) contentViewFrame
{
    return [self contentViewFrame:CurrentInterfaceOrientation];
}

- (void) applyLocalization
{
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void)adjustViewHeight
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if (bottomMargin == 0.0)
        return;
    
    CGRect cancelFrame = self.buttonsView.frame;
    cancelFrame.size.height = bottomSheetCancelButtonHeight + bottomMargin;
    cancelFrame.origin.y = DeviceScreenHeight - cancelFrame.size.height;
    self.buttonsView.frame = cancelFrame;
    UIEdgeInsets buttonInsets = self.cancelButton.contentEdgeInsets;
    buttonInsets.bottom = bottomMargin;
    self.cancelButton.contentEdgeInsets = buttonInsets;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([screenObj respondsToSelector:@selector(initView)])
        [screenObj initView];
    
    if (_appearFirstTime)
        _appearFirstTime = NO;
    else
        [screenObj setupView];
    [self adjustViewHeight];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([screenObj respondsToSelector:@selector(deinitView)])
        [screenObj deinitView];
}

- (IBAction) cancelButtonClicked:(id)sender
{
    if ([screenObj respondsToSelector:@selector(cancelButtonPressed)] && ![screenObj cancelButtonPressed])
        return;
    
    [self dismiss];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (UIWindow *)windowWithLevel:(UIWindowLevel)windowLevel
{
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (window.windowLevel == windowLevel) {
            return window;
        }
    }
    return nil;
}

- (CGRect) frameForOrientation
{
    UIWindow *window = [[UIApplication sharedApplication].windows count] > 0 ? [[UIApplication sharedApplication].windows objectAtIndex:0] : nil;
    if (!window)
        window = [UIApplication sharedApplication].keyWindow;
    if([[window subviews] count] > 0)
    {
        return [[[window subviews] objectAtIndex:0] bounds];
    }
    return [[self windowWithLevel:UIWindowLevelNormal] bounds];
}
*/

- (void) setupGestures
{
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.tap setNumberOfTapsRequired:1];
    [self.backgroundView setUserInteractionEnabled:YES];
    [self.backgroundView setMultipleTouchEnabled:NO];
    [self.backgroundView addGestureRecognizer:self.tap];

    self.tapContent = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.tapContent setNumberOfTapsRequired:1];
    self.tapContent.delegate = self;
    [self.contentView addGestureRecognizer:self.tapContent];
}

- (void) commonInit
{
    _appearFirstTime = YES;
    _app = [OsmAndApp instance];
    
    self.bottomSheetWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.bottomSheetWindow.windowLevel = UIWindowLevelNormal;
    self.bottomSheetWindow.backgroundColor = [UIColor clearColor];
    self.bottomSheetWindow.rootViewController = self;
    
    UIInterfaceOrientation interfaceOrientation = CurrentInterfaceOrientation;

    CGRect frame = [self screenFrame:interfaceOrientation];
    self.view.frame = frame;
    
    CGRect contentFrame = [self contentViewFrame:interfaceOrientation];
    contentFrame.origin.y = frame.size.height + 10.0;
    self.contentView.frame = contentFrame;
    
    _tableView.oaDelegate = self;
    //_tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    _tableView.contentInset = UIEdgeInsetsZero;

    _tableBackgroundView = [[UIView alloc] initWithFrame:{0, -1, 1, 1}];
    _tableBackgroundView.backgroundColor = UIColor.whiteColor;

    //only apply the blur if the user hasn't disabled transparency effects    
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        blurEffectView.frame = _tableBackgroundView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableBackgroundView = blurEffectView;
        
        _buttonsView.backgroundColor = UIColor.clearColor;
        blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        blurEffectView.frame = _buttonsView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_buttonsView insertSubview:blurEffectView atIndex:0];
        UIView *divider = [[UIView alloc] initWithFrame:{0, 0, _buttonsView.bounds.size.width, 0.5}];
        divider.backgroundColor = UIColorFromRGB(color_divider_blur);
        divider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_buttonsView addSubview:divider];
        _cancelButton.backgroundColor = UIColor.clearColor;
    }
    else
    {
        [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.view.layer setShadowOpacity:0.3];
        [self.view.layer setShadowRadius:3.0];
        [self.view.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    }
    
    _tableBackgroundView.autoresizingMask = UIViewAutoresizingNone;
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColor.clearColor;
    [view addSubview:_tableBackgroundView];
    _tableView.backgroundView = view;
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.clipsToBounds = YES;
    
    //self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    _tableView.separatorColor = UIColorFromRGB(color_divider_light);
    
    [self setupView];
    
    [self updateTableHeaderView:interfaceOrientation];
    [self updateBackgroundViewLayout:interfaceOrientation contentOffset:{0, 0}];

    [self setupGestures];
}

- (void) updateTableHeaderView:(UIInterfaceOrientation)interfaceOrientation
{
    CGRect contentFrame = [self contentViewFrame:interfaceOrientation];
    CGFloat tableContentHeight = [self calculateTableHeight];
    if (tableContentHeight < contentFrame.size.height - _buttonsView.frame.size.height)
    {
        CGRect frame = CGRectMake(0, 0, contentFrame.size.width, contentFrame.size.height - _buttonsView.frame.size.height - tableContentHeight);
        if (_tableView.tableHeaderView)
        {
            _tableView.tableHeaderView.frame = frame;
        }
        else
        {
            UIView *headerView = [[UIView alloc] initWithFrame:frame];
            headerView.backgroundColor = UIColor.clearColor;
            headerView.opaque = NO;
            _tableView.tableHeaderView = headerView;
        }
    }
    else
    {
        _tableView.tableHeaderView = nil;
    }
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
}

- (void) show
{
    if (!self.isVisible)
        [[OABottomSheetViewStack sharedInstance] push:self];
}

- (void)applyCorrectSizes
{
    UIInterfaceOrientation currOrientation = CurrentInterfaceOrientation;
    CGSize size = [self screenSize:currOrientation];
    CGRect viewFrame = CGRectMake(0.0, 0.0, size.width, size.height);
    CGRect contentFrame = [self contentViewFrame:currOrientation];
    self.contentView.frame = contentFrame;
    self.view.frame = viewFrame;
}

- (void) showInternal
{
    _showing = YES;
    [self.bottomSheetWindow addSubview:self.view];
    [self.bottomSheetWindow makeKeyAndVisible];

    self.visible = YES;
    
//    CGRect contentFrame = [self contentViewFrame];
    BOOL animated = YES;
    
    [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
        self.backgroundView.alpha = 1;
//        self.contentView.frame = contentFrame;
        [self applyCorrectSizes];
    } completion:^(BOOL finished) {
        _showing = NO;
    }];
}

- (void) hide
{
    [self.view removeFromSuperview];
}

- (void) dismiss
{
    [self dismiss:nil animated:YES];
}

- (void) dismiss:(id)sender
{
    [self dismiss:sender animated:YES];
}

- (void) dismiss:(id)sender animated:(BOOL)animated
{
    _hiding = YES;
    self.visible = NO;
    
    NSInteger viewsCount = [[[OABottomSheetViewStack sharedInstance] bottomSheetViews] count];
    CGRect contentFrame = self.contentView.frame;
    contentFrame.origin.y = contentFrame.size.height + 10.0;
    
    [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
        self.contentView.frame = contentFrame;
        if (viewsCount == 1)
            self.backgroundView.alpha = 0;
        
    } completion:^(BOOL finished) {
        if (viewsCount == 1)
        {
            self.bottomSheetWindow.hidden = YES;
            [self.bottomSheetWindow removeFromSuperview];
            self.bottomSheetWindow.rootViewController = nil;
            self.bottomSheetWindow = nil;
        }
        _hiding = NO;

        [[OABottomSheetViewStack sharedInstance] pop:self];
    }];
}

#pragma mark -  UIGestureRecognizerDelegate

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self.tableView];
    UIView *headerView = self.tableView.tableHeaderView;
    return headerView && [headerView pointInside:[self.tableView convertPoint:point toView:headerView] withEvent:nil];
}

#pragma mark - Orientation

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL) prefersStatusBarHidden
{
    return NO;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void) setTapToDismissEnabled:(BOOL)enabled
{
    self.tap.enabled = enabled;
    self.tapContent.enabled = enabled;
}

#pragma mark - OATableViewDelegate

- (void) tableViewWillEndDragging:(OATableView *)tableView withVelocity:(CGPoint)velocity withStartOffset:(CGPoint)startOffset
{
    CGFloat offsetY = tableView.contentOffset.y;
    BOOL slidingDown = velocity.y > 500 || offsetY < -50;
    
    if (slidingDown && offsetY < 0 && startOffset.y <= 0)
        [self dismiss];
}

- (void) tableViewContentOffsetChanged:(OATableView *)tableView contentOffset:(CGPoint)contentOffset
{
    [self updateBackgroundViewLayout:CurrentInterfaceOrientation contentOffset:contentOffset];
}

- (BOOL) tableViewScrollAllowed:(OATableView *)tableView
{
    return !_rotating && !_showing && !_hiding;
}

@end

@implementation OABottomSheetViewStack

+ (instancetype) sharedInstance
{
    static OABottomSheetViewStack *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OABottomSheetViewStack alloc] init];
        _sharedInstance.bottomSheetViews = [NSMutableArray array];
    });
    
    return _sharedInstance;
}

- (void) push:(OABottomSheetViewController *)bottomSheetView
{
    for (OABottomSheetViewController *bs in self.bottomSheetViews)
    {
        if (bs != bottomSheetView)
            [bs hide];
        else
            return;
    }
    [self.bottomSheetViews addObject:bottomSheetView];
    [bottomSheetView showInternal];
}

- (void) pop:(OABottomSheetViewController *)bottomSheetView
{
    [bottomSheetView hide];
    [self.bottomSheetViews removeObject:bottomSheetView];
    OABottomSheetViewController *last = [self.bottomSheetViews lastObject];
    if (last && !last.view.superview)
        [last showInternal];
}

@end

