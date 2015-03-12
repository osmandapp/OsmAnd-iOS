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

#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
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
@property (nonatomic) UIButton *mapButton;

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

-(instancetype)initPopup
{
    self = [super init];
    if (self) {
        _isPopup = YES;
        _settingsScreen = EMapSettingsScreenMain;
        [self commonInit];
    }
    return self;
}

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen popup:(BOOL)popup
{
    self = [super init];
    if (self) {
        _isPopup = popup;
        _settingsScreen = settingsScreen;
        [self commonInit];
    }
    return self;
}

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param popup:(BOOL)popup
{
    self = [super init];
    if (self) {
        _isPopup = popup;
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
    
    if (_isPopup) {
        
        CGFloat navHeight = 34.0;
        CGRect navFrame = _navbarView.frame;
        navFrame.size.height = navHeight;
        _navbarView.frame = navFrame;
        
        _backButton.frame = CGRectMake(_backButton.frame.origin.x, 0.0, _backButton.frame.size.width, navHeight);
        _titleView.frame = CGRectMake(self.view.frame.size.width / 2.0 - _titleView.frame.size.width / 2.0, 0.0, _titleView.frame.size.width, navHeight);
        _tableView.frame = CGRectMake(0.0, navHeight, self.view.bounds.size.width, self.view.bounds.size.height - navHeight);

    } else {
        
        CGFloat big;
        CGFloat small;
        
        CGRect rect = self.view.bounds;
        if (rect.size.width > rect.size.height) {
            big = rect.size.width;
            small = rect.size.height;
        } else {
            big = rect.size.height;
            small = rect.size.width;
        }
        
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                
                
            } else {
                
                CGFloat topY = 0.0;
                CGFloat mapWidth = small;
                CGFloat mapHeight = big - 280.0;
                CGFloat mapBottom = topY + mapHeight;
                
                _mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
                _mapButton.frame = CGRectMake(0.0, topY + 64.0, mapWidth, mapHeight - 64.0);
                _tableView.frame = CGRectMake(0.0, mapBottom, small, big - mapBottom);
                
            }
            
        } else {
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                
                
            } else {
                
                CGFloat topY = 0.0;
                CGFloat mapHeight = small - topY;
                CGFloat mapWidth = big - 290.0;
                
                _mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
                _mapButton.frame = CGRectMake(0.0, topY + 64.0, mapWidth, mapHeight - 64.0);
                _tableView.frame = CGRectMake(mapWidth, 64.0, big - mapWidth, small - 64.0);

            }
            
        }
    }
}

-(CGRect)viewFramePopup
{
    return CGRectMake(0.0, DeviceScreenHeight - kMapSettingsPopupHeight, DeviceScreenWidth, kMapSettingsPopupHeight);
}

-(void)showPopupAnimated:(UIViewController *)rootViewController parentViewController:(UIViewController *)parentViewController;
{
    self.parentVC = parentViewController;
    
    [rootViewController addChildViewController:self];
    [self willMoveToParentViewController:rootViewController];

    CGRect parentFrame;
    if (_parentVC)
        parentFrame = CGRectOffset(_parentVC.view.frame, -50.0, 0.0);
    
    CGRect frame = [self viewFramePopup];
    if (_settingsScreen == EMapSettingsScreenMain)
        frame.origin.y = DeviceScreenHeight + 10.0;
    else
        frame.origin.x = DeviceScreenWidth + 10.0;

    self.view.frame = frame;
    [rootViewController.view addSubview:self.view];
    [UIView animateWithDuration:.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (_parentVC) {
            _parentVC.view.frame = parentFrame;
            _parentVC.view.alpha = 0.0;
        }
        self.view.frame = [self viewFramePopup];
        
    } completion:^(BOOL finished) {
        [self didMoveToParentViewController:rootViewController];
        if (_parentVC)
            _parentVC.view.hidden = YES;
    }];
}

-(void)hidePopup:(BOOL)hideAll
{
    if (!_isPopup)
        return;
    
    CGRect parentFrame;
    if (_parentVC) {
        parentFrame = CGRectOffset(_parentVC.view.frame, 50.0, 0.0);
        _parentVC.view.alpha = 0.0;
        _parentVC.view.hidden = NO;
    }
    
    [UIView animateWithDuration:.4 animations:^{
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            if (_settingsScreen == EMapSettingsScreenMain || hideAll)
                self.view.frame = CGRectMake(0.0, DeviceScreenHeight + 10.0, self.view.bounds.size.width, self.view.bounds.size.height);
            else
                self.view.frame = CGRectMake(DeviceScreenWidth + 10.0, self.view.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
        } else {
            self.view.frame = CGRectMake(DeviceScreenWidth + 10.0, self.view.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
        }

        if (_parentVC && !hideAll) {
            _parentVC.view.frame = parentFrame;
            _parentVC.view.alpha = 1.0;
        }

    } completion:^(BOOL finished) {
        
        [self deleteParentVC:hideAll];
        
    }];
}

-(void)deleteParentVC:(BOOL)deleteAll
{
    if (_parentVC) {
        if (deleteAll) {
            OAMapSettingsViewController *ctrl = (OAMapSettingsViewController *)_parentVC;
            [ctrl deleteParentVC:YES];
        }
        self.parentVC = nil;
    }
    [self removeFromParentViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (_isPopup/* && _settingsScreen != EMapSettingsScreenMain*/)
        self.view.frame = [self viewFramePopup];
    
    [self setupView];
    
    if (!_isPopup) {
        CGRect f = _mapView.frame;
        self.mapButton = [[UIButton alloc] initWithFrame:CGRectMake(f.origin.x, f.origin.y + 64.0, f.size.width, f.size.height)];
        [_mapButton setTitle:@"" forState:UIControlStateNormal];
        [_mapButton addTarget:self action:@selector(doGoToMap) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.mapButton];

    } else {
        [_mapView removeFromSuperview];
        if (_settingsScreen == EMapSettingsScreenMain)
            [_backButton removeFromSuperview];

        [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.view.layer setShadowOpacity:0.8];
        [self.view.layer setShadowRadius:3.0];
        [self.view.layer setShadowOffset:CGSizeMake(2.0, 2.0)];

    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (isAppearFirstTime)
        isAppearFirstTime = NO;
    else
        [screenObj setupView];
    
    
    if (!_isPopup) {
        OAGpxBounds bounds;
        bounds.topLeft = CLLocationCoordinate2DMake(DBL_MAX, DBL_MAX);
        [[OARootViewController instance].mapPanel prepareMapForReuse:self.mapView mapBounds:bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_isPopup)
        [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (!_isPopup && _goToMap) {
        [[OARootViewController instance].mapPanel modifyMapAfterReuse:self.goToBounds azimuth:0.0 elevationAngle:90.0 animated:YES];
    }
}

-(IBAction)backButtonClicked:(id)sender
{
    if (_lastMapSourceChangeObserver) {
        [_lastMapSourceChangeObserver detach];
        _lastMapSourceChangeObserver = nil;
    }
    
    if (!_isPopup) {
        [super backButtonClicked:sender];
        
    } else {
        [self hidePopup:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)commonInit {
    
    _goToMap = NO;
    isAppearFirstTime = YES;
    self.app = [OsmAndApp instance];
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    
}

- (void)doGoToMap
{
    OARootViewController* rootViewController = [OARootViewController instance];
    [rootViewController closeMenuAndPanelsAnimated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
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
