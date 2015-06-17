//
//  OAMapSettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSettingsViewController.h"
#import "OAAppSettings.h"

#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"

#import "OAMapSettingsMainScreen.h"
#import "OAMapSettingsMapTypeScreen.h"
#import "OAMapSettingsCategoryScreen.h"
#import "OAMapSettingsParameterScreen.h"
#import "OAMapSettingsSettingScreen.h"
#import "OAMapSettingsGpxScreen.h"
#import "OAMapSettingsOverlayUnderlayScreen.h"
#import "OAMapSettingsLanguageScreen.h"
#import "OAMapSettingsPreferredLanguageScreen.h"
#import "Localization.h"
#import "OAUtilities.h"

#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Map/ObfMapObjectsProvider.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>
#if defined(OSMAND_IOS_DEV)
#   include <OsmAndCore/Map/ObfMapObjectsMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapPrimitivesMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapRasterMetricsLayerProvider.h>
#endif // defined(OSMAND_IOS_DEV)



@interface OAMapSettingsViewController () {

    BOOL isAppearFirstTime;
    BOOL isOnlineMapSource;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
}

@property (nonatomic) NSArray* tableData;
@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) EMapSettingsScreen settingsScreen;
@property (nonatomic) id<OAMapSettingsScreen> screenObj;

@property (nonatomic) id customParam;

@end

@implementation OAMapSettingsViewController

@synthesize screenObj, customParam;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _settingsScreen = EMapSettingsScreenMain;
        [self commonInit];
    }
    return self;
}

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen
{
    self = [super init];
    if (self) {
        _settingsScreen = settingsScreen;
        [self commonInit];
    }
    return self;
}

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param
{
    self = [super init];
    if (self) {
        _settingsScreen = settingsScreen;
        customParam = param;
        [self commonInit];
    }
    return self;
    
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout:self.interfaceOrientation];
}

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    self.view.frame = [self contentViewFrame:interfaceOrientation];
    _navbarView.frame = [self navbarViewFrame:interfaceOrientation];
    _navbarBackgroundView.frame = [self navbarViewFrame:interfaceOrientation];
    
    [self updateNavbarBackground:interfaceOrientation];
}


-(CGRect)contentViewFrame:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        return CGRectMake(0.0, DeviceScreenHeight - kMapSettingsContentHeight, DeviceScreenWidth, kMapSettingsContentHeight);
    }
    else
    {
        return CGRectMake(0.0, 64.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? kMapSettingsLandscapeWidth : 320.0, DeviceScreenHeight - 64.0);
    }
}

-(CGRect)contentViewFrame
{
    return [self contentViewFrame:self.interfaceOrientation];
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

-(CGRect)navbarViewFrame
{
    return [self navbarViewFrame:self.interfaceOrientation];
}

-(void)show:(UIViewController *)rootViewController parentViewController:(OAMapSettingsViewController *)parentViewController animated:(BOOL)animated;
{
    self.parentVC = parentViewController;
    
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
    if (_settingsScreen == EMapSettingsScreenMain && UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
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

-(void)hide:(BOOL)hideAll animated:(BOOL)animated
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
    
    if (!_parentVC || hideAll)
        [[OARootViewController instance].mapPanel setTopControlsVisible:YES];
    
    if (animated)
    {
        [UIView animateWithDuration:.3 animations:^{

            CGRect navbarFrame;
            CGRect contentFrame;
            
            if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            {
                if (_settingsScreen == EMapSettingsScreenMain || hideAll)
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
                OAMapSettingsViewController *topVC = self;
                OAMapSettingsViewController *pVC = _parentVC;
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

-(void)deleteParentVC:(BOOL)deleteAll
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

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"map_settings_map");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

-(void)updateNavbarBackground:(UIInterfaceOrientation)interfaceOrientation
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    _navbarBackgroundView.hidden = YES;
    [self updateNavbarBackground:self.interfaceOrientation];
    
    [self setupView];
    
    if (_settingsScreen == EMapSettingsScreenMain)
        [_backButton removeFromSuperview];
    
    [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.view.layer setShadowOpacity:0.8];
    [self.view.layer setShadowRadius:3.0];
    [self.view.layer setShadowOffset:CGSizeMake(-2.0, 2.0)];
    
    [self updateLayout:self.interfaceOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (isAppearFirstTime)
        isAppearFirstTime = NO;
    else
        [screenObj setupView];
    
}

-(IBAction)backButtonClicked:(id)sender
{
    if (_lastMapSourceChangeObserver)
    {
        [_lastMapSourceChangeObserver detach];
        _lastMapSourceChangeObserver = nil;
    }
    
    [self hide:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)commonInit
{
    isAppearFirstTime = YES;
    self.app = [OsmAndApp instance];
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    self.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight);
}

-(void)setupView {
    
    switch (_settingsScreen) {
        case EMapSettingsScreenMain:
            if (!screenObj)
                screenObj = [[OAMapSettingsMainScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenGpx:
            if (!screenObj)
                screenObj = [[OAMapSettingsGpxScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenMapType:
            if (!screenObj)
                screenObj = [[OAMapSettingsMapTypeScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenCategory:
            if (!screenObj)
                screenObj = [[OAMapSettingsCategoryScreen alloc] initWithTable:self.tableView viewController:self param:customParam];
            break;
        case EMapSettingsScreenParameter:
            if (!screenObj)
                screenObj = [[OAMapSettingsParameterScreen alloc] initWithTable:self.tableView viewController:self param:customParam];
            break;
        case EMapSettingsScreenSetting:
            if (!screenObj)
                screenObj = [[OAMapSettingsSettingScreen alloc] initWithTable:self.tableView viewController:self param:customParam];
            break;
        case EMapSettingsScreenOverlay:
            if (!screenObj)
                screenObj = [[OAMapSettingsOverlayUnderlayScreen alloc] initWithTable:self.tableView viewController:self param:@"overlay"];
        case EMapSettingsScreenUnderlay:
            if (!screenObj)
                screenObj = [[OAMapSettingsOverlayUnderlayScreen alloc] initWithTable:self.tableView viewController:self param:@"underlay"];
        case EMapSettingsScreenLanguage:
            if (!screenObj)
                screenObj = [[OAMapSettingsLanguageScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenPreferredLanguage:
            if (!screenObj)
                screenObj = [[OAMapSettingsPreferredLanguageScreen alloc] initWithTable:self.tableView viewController:self];
            break;
            
        default:
            break;
    }

    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    
    BOOL _isOnlineMapSourcePrev = isOnlineMapSource;
    isOnlineMapSource = (resource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources);
    
    screenObj.isOnlineMapSource = isOnlineMapSource;
    
    
    if (!self.tableView.dataSource)
        self.tableView.dataSource = screenObj;
    if (!self.tableView.delegate)
        self.tableView.delegate = screenObj;
    if (!self.tableView.tableFooterView)
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [screenObj setupView];

    self.titleView.text = screenObj.title;
    
    if (_isOnlineMapSourcePrev != isOnlineMapSource)
        [self.view setNeedsLayout];
    
}


- (void)onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
