//
//  OAMapPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapPanelViewController.h"

#import "OsmAndApp.h"
#import "UIViewController+OARootViewController.h"
#import "OABrowseMapAppModeHudViewController.h"
#import "OADriveAppModeHudViewController.h"
#import "OAMapViewController.h"
#import "OAAutoObserverProxy.h"
#import "OALog.h"
#import "OAIAPHelper.h"
#import "OAGPXItemViewController.h"
#import "OAGPXEditItemViewController.h"
#import "OAGPXDatabase.h"
#import <UIViewController+JASidePanel.h>
#import "OADestinationCardsViewController.h"
#import "OAPluginPopupViewController.h"
#import "OATargetDestinationViewController.h"
#import "OATargetHistoryItemViewController.h"

#import <EventKit/EventKit.h>

#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OAMapSettingsViewController.h"
#import "OAPOISearchViewController.h"
#import "OAPOIType.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "Localization.h"
#import "InfoWidgetsView.h"
#import "OAAppSettings.h"
#import "OASavingTrackHelper.h"
#import "PXAlertView.h"
#import "OATrackIntervalDialogView.h"
#import "OAParkingViewController.h"
#import "OAFavoriteViewController.h"
#import "OAPOIViewController.h"
#import "OAWikiMenuViewController.h"
#import "OAWikiWebViewController.h"
#import "OAGPXWptViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAGPXListViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAGPXRouter.h"
#import "OADestinationsHelper.h"
#import "OAHistoryItem.h"
#import "OAGPXEditWptViewController.h"
#import "OAGPXEditToolbarViewController.h"
#import "OAPOI.h"
#import "OAPOILocationType.h"
#import "OAFirebaseHelper.h"
#import "OATargetMultiView.h"

#import <UIAlertView+Blocks.h>
#import <UIAlertView-Blocks/RIButtonItem.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/CachingRoadLocator.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>
#include <OsmAndCore/ICU.h>


#define _(name) OAMapPanelViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define kMaxRoadDistanceInMeters 1000

typedef enum
{
    EOATargetPoint = 0,
    EOATargetBBOX,
    
} EOATargetMode;

@interface OAMapPanelViewController () <OADestinationViewControllerProtocol, InfoWidgetsViewDelegate, OAParkingDelegate, OAWikiMenuDelegate, OAGPXWptViewControllerDelegate>

@property (nonatomic) OABrowseMapAppModeHudViewController *browseMapViewController;
@property (nonatomic) OADriveAppModeHudViewController *driveModeViewController;
@property (nonatomic) OADestinationViewController *destinationViewController;
@property (nonatomic) InfoWidgetsView *widgetsView;

@property (strong, nonatomic) OATargetPointView* targetMenuView;
@property (strong, nonatomic) OATargetMultiView* targetMultiMenuView;
@property (strong, nonatomic) UIButton* shadowButton;

@property (nonatomic, strong) UIViewController* prevHudViewController;

@end

@implementation OAMapPanelViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASavingTrackHelper *_recHelper;

    OAAutoObserverProxy* _appModeObserver;
    OAAutoObserverProxy* _addonsSwitchObserver;
    OAAutoObserverProxy* _destinationRemoveObserver;

    BOOL _hudInvalidated;
    
    BOOL _mapNeedsRestore;
    OAMapMode _mainMapMode;
    OsmAnd::PointI _mainMapTarget31;
    float _mainMapZoom;
    float _mainMapAzimuth;
    float _mainMapEvelationAngle;
    
    NSString *_formattedTargetName;
    double _targetLatitude;
    double _targetLongitude;
    double _targetZoom;
    EOATargetMode _targetMode;
    
    OADestination *_targetDestination;

    OAMapSettingsViewController *_mapSettings;
    OAPOISearchViewController *_searchPOI;
    UILongPressGestureRecognizer *_shadowLongPress;
    
    BOOL _customStatusBarStyleNeeded;
    UIStatusBarStyle _customStatusBarStyle;
    
    BOOL _mapStateSaved;
    
    BOOL _activeTargetActive;
    OATargetPointType _activeTargetType;
    id _activeTargetObj;
    id _activeViewControllerState;
    BOOL _activeTargetChildPushed;
    
    UIView *_shadeView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

    _settings = [OAAppSettings sharedManager];
    _recHelper = [OASavingTrackHelper sharedInstance];

    _appModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onAppModeChanged)
                                                  andObserve:_app.appModeObservable];
    
    _addonsSwitchObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onAddonsSwitch:withKey:andValue:)
                                                       andObserve:_app.addonsSwitchObservable];

    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemove:withKey:)
                                                            andObserve:_app.data.destinationRemoveObservable];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTargetPointSet:) name:kNotificationSetTargetPoint object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNoSymbolFound:) name:kNotificationNoSymbolFound object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMapGestureAction:) name:kNotificationMapGestureAction object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContextMarkerClicked:) name:kNotificationContextMarkerClicked object:nil];

    _hudInvalidated = NO;
}

- (void)loadView
{
    OALog(@"Creating Map Panel views...");
    
    // Create root view
    UIView* rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = rootView;
    
    // Instantiate map view controller
    _mapViewController = [[OAMapViewController alloc] init];
    [self addChildViewController:_mapViewController];
    [self.view addSubview:_mapViewController.view];
    _mapViewController.view.frame = self.view.frame;
    _mapViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Setup target point menu
    self.targetMenuView = [[OATargetPointView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 140.0)];
    self.targetMenuView.delegate = self;
    [self.targetMenuView setMapViewInstance:_mapViewController.view];
    [self.targetMenuView setParentViewInstance:self.view];

    [self resetActiveTargetMenu];

    // Setup target multi menu
    self.targetMultiMenuView = [[OATargetMultiView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 140.0)];

    _widgetsView = [[InfoWidgetsView alloc] init];
    _widgetsView.delegate = self;
    
    [self updateHUD:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_widgetsView updateGpxRec];

    if (_hudInvalidated)
    {
        [self updateHUD:animated];
        _hudInvalidated = NO;
    }
    
    if (_mapNeedsRestore) {
        _mapNeedsRestore = NO;
        [self restoreMapAfterReuse];
    }
    
    self.sidePanelController.recognizesPanGesture = NO; //YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.targetMenuView setNavigationController:self.navigationController];

    if ([_mapViewController parentViewController] != self)
        [self doMapRestore];
}

- (void)viewWillLayoutSubviews
{
    if ([self contextMenuMode])
        [self doUpdateContextMenuToolbarLayout];
    else if (_destinationViewController)
        [_destinationViewController updateFrame:YES];
    
    if (_shadowButton)
        _shadowButton.frame = [self shadowButtonRect];
}
 
@synthesize mapViewController = _mapViewController;
@synthesize hudViewController = _hudViewController;

- (void)doUpdateContextMenuToolbarLayout
{
    CGFloat contextMenuToolbarHeight = [self.targetMenuView toolbarHeight];
    
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController updateContextMenuToolbarLayout:contextMenuToolbarHeight animated:YES];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController updateContextMenuToolbarLayout:contextMenuToolbarHeight animated:YES];
}

- (void) infoSelectPressed
{
    BOOL recOn = _settings.mapSettingTrackRecording;

    if (recOn)
    {
        
        [PXAlertView showAlertWithTitle:OALocalizedString(@"track_recording")
                                                     message:nil
                                                 cancelTitle:OALocalizedString(@"shared_string_cancel")
                                                 otherTitles:@[ OALocalizedString(@"track_stop_rec"), OALocalizedString(@"show_info"), OALocalizedString(@"track_new_segment"), OALocalizedString(@"track_save") ]
                                                   otherDesc:nil
                                                 otherImages:@[@"track_recording_stop.png", @"icon_info.png", @"track_new_segement.png" , @"track_save.png"]
                                                  completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                                      if (!cancelled) {
                                                          switch (buttonIndex) {
                                                              case 0:
                                                              {
                                                                  _settings.mapSettingTrackRecording = NO;
                                                                  break;
                                                              }
                                                              case 1:
                                                              {
                                                                  [self openTargetViewWithGPX:nil pushed:NO];
                                                                  break;
                                                              }
                                                              case 2:
                                                              {
                                                                  [_recHelper startNewSegment];
                                                                  break;
                                                              }
                                                              case 3:
                                                              {
                                                                  if ([_recHelper hasDataToSave] && _recHelper.distance < 10.0)
                                                                  {
                                                                      [PXAlertView showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                                                                              message:nil
                                                                                          cancelTitle:OALocalizedString(@"shared_string_no")
                                                                                           otherTitle:OALocalizedString(@"shared_string_yes")
                                                                                            otherDesc:nil
                                                                                           otherImage:nil
                                                                                           completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                                                                               if (!cancelled) {
                                                                                                   _settings.mapSettingTrackRecording = NO;
                                                                                                   [self saveTrack:YES];
                                                                                               }
                                                                                           }];
                                                                  }
                                                                  else
                                                                  {
                                                                      _settings.mapSettingTrackRecording = NO;
                                                                      [self saveTrack:YES];
                                                                  }
                                                                  break;
                                                              }
                                                              default:
                                                                  break;
                                                          }
                                                      }
                                                  }];

    }
    else
    {
        if ([_recHelper hasData])
        {
            [PXAlertView showAlertWithTitle:OALocalizedString(@"track_recording")
                                    message:nil
                                cancelTitle:OALocalizedString(@"shared_string_cancel")
                                 otherTitles:@[OALocalizedString(@"track_continue_rec"), OALocalizedString(@"show_info"), OALocalizedString(@"track_clear"), OALocalizedString(@"track_save")]
                                  otherDesc:nil
                                otherImages:@[@"ic_action_rec_start.png", @"icon_info.png", @"track_clear_data.png", @"track_save.png"]
                                 completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                     if (!cancelled) {
                                         switch (buttonIndex) {
                                             case 0:
                                             {
                                                 [_recHelper startNewSegment];
                                                 _settings.mapSettingTrackRecording = YES;
                                                 break;
                                             }
                                             case 1:
                                             {
                                                 [self openTargetViewWithGPX:nil pushed:NO];
                                                 break;
                                             }
                                             case 2:
                                             {
                                                 [PXAlertView showAlertWithTitle:OALocalizedString(@"track_clear_q")
                                                                         message:nil
                                                                     cancelTitle:OALocalizedString(@"shared_string_no")
                                                                      otherTitle:OALocalizedString(@"shared_string_yes")
                                                                       otherDesc:nil
                                                                      otherImage:nil
                                                                      completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                                                          if (!cancelled)
                                                                          {
                                                                              [_recHelper clearData];
                                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                                  [_mapViewController hideContextPinMarker];
                                                                                  [_mapViewController hideRecGpxTrack];
                                                                                  [_widgetsView updateGpxRec];
                                                                              });
                                                                          }
                                                                      }];
                                                 break;
                                             }
                                             case 3:
                                             {
                                                 if ([_recHelper hasDataToSave] && _recHelper.distance < 10.0)
                                                 {
                                                     [PXAlertView showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                                                             message:nil
                                                                         cancelTitle:OALocalizedString(@"shared_string_no")
                                                                          otherTitle:OALocalizedString(@"shared_string_yes")
                                                                           otherDesc:nil
                                                                          otherImage:nil
                                                                          completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                                                              if (!cancelled) {
                                                                                  [self saveTrack:NO];
                                                                              }
                                                                          }];
                                                 }
                                                 else
                                                 {
                                                     [self saveTrack:NO];
                                                 }
                                                 break;
                                             }
                                                 
                                             default:
                                                 break;
                                         }
                                     }
                                 }];
        }
        else
        {
            if (!_settings.mapSettingSaveTrackIntervalApproved)
            {
                OATrackIntervalDialogView *view = [[OATrackIntervalDialogView alloc] initWithFrame:CGRectMake(0.0, 0.0, 252.0, 116.0)];
                
                [PXAlertView showAlertWithTitle:OALocalizedString(@"track_start_rec")
                                        message:nil
                                    cancelTitle:OALocalizedString(@"shared_string_cancel")
                                     otherTitle:OALocalizedString(@"shared_string_ok")
                                      otherDesc:nil
                                     otherImage:nil
                                    contentView:view
                                     completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                         
                                         if (!cancelled)
                                         {
                                             _settings.mapSettingSaveTrackIntervalGlobal = [_settings.trackIntervalArray[[view getInterval]] intValue];
                                             if (view.swRemember.isOn)
                                                 _settings.mapSettingSaveTrackIntervalApproved = YES;

                                             _settings.mapSettingTrackRecording = YES;
                                         }
                                     }];
            }
            else
            {
                _settings.mapSettingTrackRecording = YES;
            }
            
        }
    }
}

- (void) saveTrack:(BOOL)askForRec
{
    if ([_recHelper hasDataToSave])
        [_recHelper saveDataToGpx];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapViewController hideContextPinMarker];
        [_widgetsView updateGpxRec];
    });
    
    if (_activeTargetActive && [self hasGpxActiveTargetType] && !_activeTargetObj)
    {
        [self targetHideMenu:.3 backButtonClicked:NO];
    }
    
    if (askForRec)
    {
        [PXAlertView showAlertWithTitle:OALocalizedString(@"track_continue_rec_q")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_no")
                             otherTitle:OALocalizedString(@"shared_string_yes")
                              otherDesc:nil
                             otherImage:nil
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled) {
                                     _settings.mapSettingTrackRecording = YES;
                                     
                                 }
                             }];
    }
}

- (void)updateHUD:(BOOL)animated
{
    if (!_destinationViewController) {
        _destinationViewController = [[OADestinationViewController alloc] initWithNibName:@"OADestinationViewController" bundle:nil];
        _destinationViewController.delegate = self;

        for (OADestination *destination in _app.data.destinations)
            if (!destination.routePoint && !destination.hidden)
                [_mapViewController addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude];

    }
    
    // Inflate new HUD controller and add it
    UIViewController* newHudController = nil;
    if (_app.appMode == OAAppModeBrowseMap)
    {
        if (!self.browseMapViewController) {
            self.browseMapViewController = [[OABrowseMapAppModeHudViewController alloc] initWithNibName:@"BrowseMapAppModeHUD"
                                                                                   bundle:nil];
            _browseMapViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _browseMapViewController.destinationViewController = self.destinationViewController;
            if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
                _browseMapViewController.widgetsView = self.widgetsView;
            else
                _browseMapViewController.widgetsView = nil;
            
        }
        
        newHudController = self.browseMapViewController;

        _mapViewController.view.frame = self.view.frame;
    }
    else if (_app.appMode == OAAppModeDrive)
    {
        if (!self.driveModeViewController) {
            self.driveModeViewController = [[OADriveAppModeHudViewController alloc] initWithNibName:@"DriveAppModeHUD"
                                                                               bundle:nil];
            _driveModeViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _driveModeViewController.destinationViewController = self.destinationViewController;
            if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
                _driveModeViewController.widgetsView = self.widgetsView;
            else
                _driveModeViewController.widgetsView = nil;
        }

        newHudController = self.driveModeViewController;
        
        CGRect frame = self.view.frame;
        frame.origin.y = 64.0;
        frame.size.height = DeviceScreenHeight - 64.0;
        _mapViewController.view.frame = frame;

    }
    [self addChildViewController:newHudController];

    // Switch views
    newHudController.view.frame = self.view.frame;
    [self.view addSubview:newHudController.view];
    
    if (animated && _hudViewController != nil)
    {
        _prevHudViewController = _hudViewController;
        [UIView transitionFromView:_hudViewController.view
                            toView:newHudController.view
                          duration:0.6
                           options:UIViewAnimationOptionTransitionFlipFromTop
         
                        completion:^(BOOL finished) {
                            [_prevHudViewController.view removeFromSuperview];
                            _prevHudViewController = nil;
                        }];
    }
    else
    {
        if (_hudViewController != nil)
            [_hudViewController.view removeFromSuperview];
    }

    // Remove previous view controller if such exists
    if (_hudViewController != nil)
        [_hudViewController removeFromParentViewController];
    _hudViewController = newHudController;
    
    [_destinationViewController updateFrame:NO];

    [self.rootViewController setNeedsStatusBarAppearanceUpdate];
}

- (void)updateOverlayUnderlayView:(BOOL)show
{
    if (self.browseMapViewController)
        [_browseMapViewController updateOverlayUnderlayView:show];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (_customStatusBarStyleNeeded)
        return _customStatusBarStyle;

    if ([self contextMenuMode])
    {
        if ([self.targetMenuView isToolbarVisible] || [self.targetMenuView isInFullScreenMode] || [self.targetMenuView isLandscape])
            return UIStatusBarStyleLightContent;
        else
            return UIStatusBarStyleDefault;
    }
    else if (self.targetMenuView.superview)
    {
        if ([self.targetMenuView isToolbarVisible])
            return UIStatusBarStyleLightContent;
        else if ([self.targetMenuView isInFullScreenMode] || [self.targetMenuView isLandscape])
            return UIStatusBarStyleDefault;
    }
    
    if (_hudViewController == nil)
        return UIStatusBarStyleDefault;
    
    return _hudViewController.preferredStatusBarStyle;
}

- (BOOL)hasGpxActiveTargetType
{
    return _activeTargetType == OATargetGPX || _activeTargetType == OATargetGPXEdit;
}

- (void)onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _hudInvalidated = YES;
            return;
        }

        [self updateHUD:YES];
    });
}

- (void)onAddonsSwitch:(id)observable withKey:(id)key andValue:(id)value
{
    NSString *productIdentifier = key;
    if ([productIdentifier isEqualToString:kInAppId_Addon_TrackRecording])
    {
        BOOL active = [value boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!active)
            {
                _settings.mapSettingTrackRecording = NO;

                if ([_recHelper hasDataToSave])
                    [_recHelper saveDataToGpx];

                [_mapViewController hideRecGpxTrack];
                
                if (self.browseMapViewController)
                    _browseMapViewController.widgetsView = nil;
                if (self.driveModeViewController)
                    _driveModeViewController.widgetsView = nil;
                [self.widgetsView removeFromSuperview];
            }
            else
            {
                if (_app.appMode == OAAppModeBrowseMap)
                {
                    if (self.browseMapViewController)
                        _browseMapViewController.widgetsView = self.widgetsView;
                }
                else if (_app.appMode == OAAppModeDrive)
                {
                    if (self.driveModeViewController)
                        _driveModeViewController.widgetsView = self.widgetsView;
                }
            }
        });
    }
    else if ([productIdentifier isEqualToString:kInAppId_Addon_Srtm])
    {
        [_app.data.mapLayerChangeObservable notifyEvent];
    }
}

- (void)saveMapStateIfNeeded
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if ([_mapViewController parentViewController] == self) {
        
        _mapNeedsRestore = YES;
        _mainMapMode = _app.mapMode;
        _mainMapTarget31 = renderView.target31;
        _mainMapZoom = renderView.zoom;
        _mainMapAzimuth = renderView.azimuth;
        _mainMapEvelationAngle = renderView.elevationAngle;
    }
}

- (void)saveMapStateNoRestore
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    _mapNeedsRestore = NO;
    _mainMapMode = _app.mapMode;
    _mainMapTarget31 = renderView.target31;
    _mainMapZoom = renderView.zoom;
    _mainMapAzimuth = renderView.azimuth;
    _mainMapEvelationAngle = renderView.elevationAngle;
}

- (void)prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    if (isnan(zoom))
        zoom = renderView.zoom;
    if (zoom > 22.0f)
        zoom = 22.0f;
    
    [_mapViewController goToPosition:destinationPoint
                             andZoom:zoom
                            animated:animated];
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (void)prepareMapForReuse:(UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if (mapBounds.topLeft.latitude != DBL_MAX) {
        
        const OsmAnd::LatLon latLon(mapBounds.center.latitude, mapBounds.center.longitude);
        Point31 center = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
        
        float metersPerPixel = [_mapViewController calculateMapRuler];
        
        double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
        double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
        
        CGSize mapSize;
        if (destinationView)
            mapSize = destinationView.bounds.size;
        else
            mapSize = self.view.bounds.size;
        
        CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
        CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
        CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
        
        CGFloat zoom = renderView.zoom - newZoom;
        if (isnan(zoom))
            zoom = renderView.zoom;
        if (zoom > 22.0f)
            zoom = 22.0f;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
    
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (CGFloat)getZoomForBounds:(OAGpxBounds)mapBounds mapSize:(CGSize)mapSize
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if (mapBounds.topLeft.latitude == DBL_MAX)
        return renderView.zoom;

    float metersPerPixel = [_mapViewController calculateMapRuler];
    
    double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
    double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
    
    CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
    CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
    CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
    
    CGFloat zoom = renderView.zoom - newZoom;
    if (isnan(zoom))
        zoom = renderView.zoom;
    if (zoom > 22.0f)
        zoom = 22.0f;
    
    return zoom;
}

- (void)doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView
{
    CGRect newFrame = CGRectMake(0, 0, destinationView.bounds.size.width, destinationView.bounds.size.height);
    if (!CGRectEqualToRect(_mapViewController.view.frame, newFrame))
        _mapViewController.view.frame = newFrame;

    [_mapViewController willMoveToParentViewController:nil];
    
    [destinationViewController addChildViewController:_mapViewController];
    [destinationView addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [destinationView bringSubviewToFront:_mapViewController.view];
    
    _mapViewController.minimap = YES;
}

- (void)modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated
{
    _mapNeedsRestore = NO;
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = azimuth;
    renderView.elevationAngle = elevationAngle;
    [_mapViewController goToPosition:destinationPoint andZoom:zoom animated:YES];
    
    _mapViewController.minimap = NO;
}

- (void)modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated
{
    _mapNeedsRestore = NO;
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = azimuth;
    renderView.elevationAngle = elevationAngle;
    
    if (mapBounds.topLeft.latitude != DBL_MAX) {
        
        const OsmAnd::LatLon latLon(mapBounds.center.latitude, mapBounds.center.longitude);
        Point31 center = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
        
        float metersPerPixel = [_mapViewController calculateMapRuler];
        
        double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
        double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
        
        CGSize mapSize = self.view.bounds.size;
        
        CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
        CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
        CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
        
        CGFloat zoom = renderView.zoom - newZoom;
        if (isnan(zoom))
            zoom = renderView.zoom;
        if (zoom > 22.0f)
            zoom = 22.0f;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
    
    _mapViewController.minimap = NO;
}

- (void)restoreMapAfterReuse
{
    _app.mapMode = _mainMapMode;
    
    OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
    mapView.target31 = _mainMapTarget31;
    mapView.zoom = _mainMapZoom;
    mapView.azimuth = _mainMapAzimuth;
    mapView.elevationAngle = _mainMapEvelationAngle;
    
    _mapViewController.minimap = NO;
}

- (void)restoreMapAfterReuseAnimated
{
    _app.mapMode = _mainMapMode;
 
    if (_mainMapMode == OAMapModeFree || _mainMapMode == OAMapModeUnknown)
    {
        OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
        mapView.azimuth = _mainMapAzimuth;
        mapView.elevationAngle = _mainMapEvelationAngle;
        [_mapViewController goToPosition:[OANativeUtilities convertFromPointI:_mainMapTarget31] andZoom:_mainMapZoom animated:YES];
    }
    
    _mapViewController.minimap = NO;
}

- (void)doMapRestore
{
    [_mapViewController hideTempGpxTrack];
    
    _mapViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [_mapViewController willMoveToParentViewController:nil];
    
    [self addChildViewController:_mapViewController];
    [self.view addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [self.view sendSubviewToBack:_mapViewController.view];
    
}

- (void)hideContextMenu
{
    [self targetHideMenu:.2 backButtonClicked:NO];
}

-(void)closeMapSettings
{
    [self closeMapSettingsWithDuration:.3];
}

- (void)closeMapSettingsWithDuration:(CGFloat)duration
{
    if (_mapSettings)
    {
        [self updateOverlayUnderlayView:[_browseMapViewController isOverlayUnderlayViewVisible]];
        
        OAMapSettingsViewController* lastMapSettingsCtrl = [self.childViewControllers lastObject];
        if (lastMapSettingsCtrl)
            [lastMapSettingsCtrl hide:YES animated:YES duration:duration];
        
        _mapSettings = nil;
        
        [self destroyShadowButton];

        [self.targetMenuView quickShow];

        self.sidePanelController.recognizesPanGesture = NO; //YES;
    }
}

-(CGRect)shadowButtonRect
{
    return self.view.frame;
}

- (void)removeGestureRecognizers
{
    while (self.view.gestureRecognizers.count > 0)
        [self.view removeGestureRecognizer:self.view.gestureRecognizers[0]];
}

- (void)mapSettingsButtonClick:(id)sender
{
    [OAFirebaseHelper logEvent:@"configure_map_open"];
    
    [self removeGestureRecognizers];
    
    _mapSettings = [[OAMapSettingsViewController alloc] init];
    [_mapSettings show:self parentViewController:nil animated:YES];
    
    [self createShadowButton:@selector(closeMapSettings) withLongPressEvent:nil topView:_mapSettings.view];
    
    [self.targetMenuView quickHide];

    self.sidePanelController.recognizesPanGesture = NO;
}

- (void)searchButtonClick:(id)sender
{
    [OAFirebaseHelper logEvent:@"search_open"];

    [self removeGestureRecognizers];

    OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
    BOOL isMyLocationVisible = [_mapViewController isMyLocationVisible];

    BOOL searchNearMapCenter = NO;
    OsmAnd::PointI searchLocation;

    CLLocation* newLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    OsmAnd::PointI myLocation;
    double distanceFromMyLocation = 0;
    if (newLocation)
    {
        myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude));
        if (!isMyLocationVisible)
        {
            distanceFromMyLocation = OsmAnd::Utilities::distance31(myLocation, mapView.target31);
            if (distanceFromMyLocation > 15000)
            {
                searchNearMapCenter = YES;
                searchLocation = mapView.target31;
            }
            else
            {
                searchLocation = myLocation;
            }
        }
        else
        {
            searchLocation = myLocation;
        }
    }
    else
    {
        searchNearMapCenter = YES;
        searchLocation = mapView.target31;
    }

    
    if (!_searchPOI)
        _searchPOI = [[OAPOISearchViewController alloc] init];
    _searchPOI.myLocation = searchLocation;
    _searchPOI.distanceFromMyLocation = distanceFromMyLocation;
    _searchPOI.searchNearMapCenter = searchNearMapCenter;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_searchPOI];
    navController.navigationBarHidden = YES;
    navController.automaticallyAdjustsScrollViewInsets = NO;
    navController.edgesForExtendedLayout = UIRectEdgeNone;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

-(void)onNoSymbolFound:(NSNotification *)notification
{
    //[self hideTargetPointMenu];
    [self.targetMenuView hideByMapGesture];
}

-(void)onMapGestureAction:(NSNotification *)notification
{
    [self.targetMenuView hideByMapGesture];
}

-(void)onContextMarkerClicked:(NSNotification *)notification
{
    if (!self.targetMenuView.superview)
    {
        [self showTargetPointMenu:YES showFullMenu:NO];
    }
}

-(NSString *)convertHTML:(NSString *)html
{
    NSScanner *myScanner;
    NSString *text = nil;
    myScanner = [NSScanner scannerWithString:html];
    
    while ([myScanner isAtEnd] == NO) {
        
        [myScanner scanUpToString:@"<" intoString:NULL] ;
        
        [myScanner scanUpToString:@">" intoString:&text] ;
        
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    //
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return html;
}

-(void)onTargetPointSet:(NSNotification *)notification
{
    NSDictionary *params = [notification userInfo];
    NSArray<OAMapSymbol *> *symbols = [params objectForKey:@"symbols"];
    double latitude = [[params objectForKey:@"latitude"] doubleValue];
    double longitude = [[params objectForKey:@"longitude"] doubleValue];
    
    if (symbols.count == 0)
    {
        return;
    }
    else if (symbols.count == 1)
    {
        if (![self applyMapSymbol:symbols[0]])
            return;
        
        OATargetPoint *targetPoint = [self getTargetPoint:symbols[0]];
        [self showContextMenu:targetPoint];
    }
    else
    {
        if (![self applyMapSymbol:symbols[0]])
            return;

        NSMutableArray<OATargetPoint *> *points = [NSMutableArray array];
        for (OAMapSymbol *symbol in symbols)
        {
            OATargetPoint *targetPoint = [self getTargetPoint:symbol];
            if (targetPoint)
            {
                [self applyTargetPointController:targetPoint];
                [points addObject:targetPoint];
            }
        }
        [self showMultiContextMenu:points latitude:latitude longitude:longitude];
    }
}

- (void)applyTargetPointController:(OATargetPoint *)targetPoint
{
    double lat = targetPoint.location.latitude;
    double lon = targetPoint.location.longitude;
    OATargetMenuViewController *controller;
    switch (targetPoint.type)
    {
        case OATargetFavorite:
        {
            OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
            for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                int favLon = (int)(OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) * 10000.0);
                int favLat = (int)(OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) * 10000.0);
                
                if ((int)(lat * 10000.0) == favLat && (int)(lon * 10000.0) == favLon)
                {
                    item.favorite = favLoc;
                    break;
                }
            }
            
            controller = [[OAFavoriteViewController alloc] initWithItem:item];
            break;
        }
            
        case OATargetDestination:
        {
            controller = [[OATargetDestinationViewController alloc] initWithDestination:targetPoint.targetObj];
            break;
        }
            
        case OATargetHistoryItem:
        {
            controller = [[OATargetHistoryItemViewController alloc] initWithHistoryItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetParking:
        {
            if (targetPoint.targetObj)
                controller = [[OAParkingViewController alloc] initWithParking:targetPoint.targetObj];
            else
                controller = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon)];
            break;
        }
            
        case OATargetPOI:
        {
            controller = [[OAPOIViewController alloc] initWithPOI:targetPoint.targetObj];
            break;
        }
            
        case OATargetWiki:
        {
            NSString *contentLocale = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            if (!contentLocale)
                contentLocale = [OAUtilities currentLang];
            
            NSString *content = [targetPoint.localizedContent objectForKey:contentLocale];
            if (!content)
            {
                contentLocale = @"";
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            if (!content && targetPoint.localizedContent.count > 0)
            {
                contentLocale = targetPoint.localizedContent.allKeys[0];
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            
            if (content)
                controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:content];
            break;
        }
            
        case OATargetWpt:
        {
            if (_activeTargetType == OATargetGPXEdit)
                controller = [[OAGPXEditWptViewController alloc] initWithItem:targetPoint.targetObj];
            else
                controller = [[OAGPXWptViewController alloc] initWithItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetGPX:
        {
            OAGPXItemViewControllerState *state = _activeViewControllerState ? (OAGPXItemViewControllerState *)_activeViewControllerState : nil;
            
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetGPXEdit:
        {
            OAGPXEditItemViewControllerState *state = _activeViewControllerState ? (OAGPXEditItemViewControllerState *)_activeViewControllerState : nil;
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetGPXRoute:
        {
            OAGPXRouteViewControllerState *state = _activeViewControllerState ? (OAGPXRouteViewControllerState *)_activeViewControllerState : nil;
            OAGpxRouteSegmentType segmentType = (OAGpxRouteSegmentType)targetPoint.segmentIndex;
            if (state)
                controller = [[OAGPXRouteViewController alloc] initWithCtrlState:state];
            else
                controller = [[OAGPXRouteViewController alloc] initWithSegmentType:segmentType];
            
            break;
        }
            
        default:
        {
        }
    }
    if (controller)
    {
        targetPoint.ctrlAttrTypeStr = [controller getAttributedTypeStr];
        targetPoint.ctrlTypeStr = [controller getTypeStr];
    }
}

- (void)showMultiContextMenu:(NSArray<OATargetPoint *> *)points latitude:(double)latitude longitude:(double)longitude
{
    // show context marker on map
    //[_mapViewController showContextPinMarker:latitude longitude:longitude animated:YES];
    
    [self showMultiPointMenu:points onComplete:^{
        
    }];
}

-(void)showContextMenu:(OATargetPoint *) targetPoint
{
    // show context marker on map
    [_mapViewController showContextPinMarker:targetPoint.location.latitude longitude:targetPoint.location.longitude animated:YES];
    
    [self applyTargetPoint:targetPoint];    
    [_targetMenuView setTargetPoint:targetPoint];
    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
        
        if (targetPoint.centerMap)
            [self goToTargetPointDefault];
        
        if (_activeTargetType == OATargetGPXEdit && targetPoint.type != OATargetWpt)
            [self targetPointAddWaypoint];
    }];
}

-(BOOL)applyMapSymbol:(OAMapSymbol *)symbol
{
    BOOL isWaypoint = symbol.type == OAMapSymbolWpt;
    
    // while we are in view GPX mode - waypoints can be pressed only
    if (_activeTargetType == OATargetGPX && !isWaypoint)
    {
        [_mapViewController hideContextPinMarker];
        return NO;
    }
    
    if (_activeTargetType == OATargetGPXEdit && isWaypoint)
    {
        NSString *path = ((OAGPX *)_activeTargetObj).gpxFileName;
        if (_mapViewController.foundWpt && ![[_mapViewController.foundWptDocPath lastPathComponent] isEqualToString:path])
        {
            [_mapViewController hideContextPinMarker];
            return NO;
        }
    }
    
    if (_activeTargetType == OATargetGPXRoute)
    {
        if (!isWaypoint)
        {
            [_mapViewController hideContextPinMarker];
            return NO;
        }
        else
        {
            NSString *path = [OAGPXRouter sharedInstance].gpx.gpxFileName;
            if (_mapViewController.foundWpt && ![[_mapViewController.foundWptDocPath lastPathComponent] isEqualToString:path])
            {
                [_mapViewController hideContextPinMarker];
                return NO;
            }
        }
    }
    return YES;
}

-(void)applyTargetPoint:(OATargetPoint *)targetPoint
{
    _targetDestination = nil;
    
    _targetMenuView.isAddressFound = targetPoint.addressFound;
    _formattedTargetName = targetPoint.title;

    if (targetPoint.type == OATargetDestination || targetPoint.type == OATargetParking)
        _targetDestination = targetPoint.targetObj;
    
    _targetMode = EOATargetPoint;
    _targetLatitude = targetPoint.location.latitude;
    _targetLongitude = targetPoint.location.longitude;
    _targetZoom = 0.0;
}

-(OATargetPoint *)getTargetPoint:(OAMapSymbol *)symbol
{
    
    unsigned long long obfId = symbol.obfId;
    OAPOIType *poiType = symbol.poiType;
    
    NSString *objectType;
    if (symbol.type == OAMapSymbolFavorite)
        objectType = @"favorite";
    else if (symbol.type == OAMapSymbolDestination)
        objectType = @"destination";
    else if (symbol.type == OAMapSymbolWpt)
        objectType = @"waypoint";
    else if (symbol.type == OAMapSymbolWiki)
        objectType = @"wiki";
    
    NSString *caption = symbol.caption ? symbol.caption : @"";
    NSString *captionExt = symbol.captionExt;
    NSString *buildingNumber = symbol.buildingNumber ? symbol.buildingNumber : @"";
    UIImage *icon = symbol.icon;
    double lat = symbol.location.latitude;
    double lon = symbol.location.longitude;
    BOOL isPlace = [symbol isPlace];
    
    NSDictionary *values = symbol.values;
    NSDictionary *names = symbol.localizedNames;
    NSDictionary *content = symbol.localizedContent;
    BOOL centerMap = symbol.centerMap;
    CGPoint touchPoint = CGPointMake(symbol.touchPoint.x, symbol.touchPoint.y);
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];

    if (_activeTargetType == OATargetGPXEdit && ![objectType isEqualToString:@"waypoint"])
    {
        objectType = nil;
        if ([_mapViewController hasWptAt:CLLocationCoordinate2DMake(symbol.location.latitude, symbol.location.longitude)])
        {
            [_mapViewController findWpt:CLLocationCoordinate2DMake(symbol.location.latitude, symbol.location.longitude)];
            objectType = @"waypoint";
        }
    }
    
    NSString* addressString;
    NSString *formattedTargetName;
    BOOL isAddressFound = NO;
    
    if (objectType && [objectType isEqualToString:@"favorite"])
    {
        for (const auto& favLoc : _app.favoritesCollection->getFavoriteLocations()) {
            
            if ([OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) destination:lon] &&
                [OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) destination:lat])
            {
                UIColor* color = [UIColor colorWithRed:favLoc->getColor().r/255.0 green:favLoc->getColor().g/255.0 blue:favLoc->getColor().b/255.0 alpha:1.0];
                OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
                
                caption = favLoc->getTitle().toNSString();
                icon = [UIImage imageNamed:favCol.iconName];
                
                targetPoint.type = OATargetFavorite;
                break;
            }
        }
        if (targetPoint.type == OATargetLocation && !poiType)
        {
            poiType = [[OAPOILocationType alloc] init];
        }
    }
    else if (objectType && [objectType isEqualToString:@"destination"])
    {
        for (OADestination *destination in _app.data.destinations)
        {
            if (destination.latitude == lat && destination.longitude == lon && !destination.routePoint)
            {
                caption = destination.desc;
                icon = [UIImage imageNamed:destination.markerResourceName];
                
                if (destination.parking)
                    targetPoint.type = OATargetParking;
                else
                    targetPoint.type = OATargetDestination;
                
                targetPoint.targetObj = destination;
                
                break;
            }
        }
        if (!targetPoint.targetObj && targetPoint.type == OATargetLocation && !poiType)
        {
            poiType = [[OAPOILocationType alloc] init];
        }
    }
    else if (objectType && [objectType isEqualToString:@"wiki"])
    {
        targetPoint.type = OATargetWiki;
    }
    else if (objectType && [objectType isEqualToString:@"waypoint"])
    {
        targetPoint.type = OATargetWpt;
        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
        item.point = symbol.foundWpt;
        item.groups = symbol.foundWptGroups;
        targetPoint.targetObj = item;
        
        UIColor* color = item.color;
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        icon = [UIImage imageNamed:favCol.iconName];
        caption = item.point.name;
    }
    
    NSString *roadTitle;
    if (!isPlace)
        roadTitle = [self findRoadNameByLat:lat lon:lon];
    
    if (caption.length == 0 && (targetPoint.type == OATargetLocation || targetPoint.type == OATargetPOI))
    {
        if (!roadTitle || roadTitle.length == 0)
        {
            if (buildingNumber.length > 0)
            {
                addressString = buildingNumber;
                isAddressFound = YES;
            }
            else
            {
                addressString = OALocalizedString(@"map_no_address");
            }
        }
        else
        {
            if (buildingNumber.length > 0)
                addressString = [NSString stringWithFormat:@"%@, %@", roadTitle, buildingNumber];
            else
                addressString = roadTitle;
            isAddressFound = YES;
        }
    }
    else if (caption.length > 0)
    {
        isAddressFound = YES;
        addressString = caption;
    }
    
    if (isAddressFound || addressString)
    {
        formattedTargetName = addressString;
    }
    else if (poiType)
    {
        isAddressFound = YES;
        formattedTargetName = poiType.nameLocalized;
    }
    else if (buildingNumber.length > 0)
    {
        isAddressFound = YES;
        formattedTargetName = buildingNumber;
    }
    else
    {
        formattedTargetName = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    }
    
    if ((targetPoint.type == OATargetLocation || targetPoint.type == OATargetWiki) && poiType)
    {
        OAPOI *poi = [[OAPOI alloc] init];
        poi.obfId = obfId;
        poi.latitude = lat;
        poi.longitude = lon;
        poi.type = poiType;
        poi.name = caption;
        poi.nameLocalized = caption;
        poi.localizedNames = names;
        poi.values = values;
        
        if (poi.name.length == 0)
            poi.name = poiType.name;
        if (poi.nameLocalized.length == 0)
            poi.nameLocalized = poiType.nameLocalized;
        if (poi.nameLocalized.length == 0)
            poi.nameLocalized = formattedTargetName;
        
        formattedTargetName = poi.nameLocalized;
        
        icon = [poiType icon];
        
        if (targetPoint.type != OATargetWiki)
        {
            targetPoint.type = OATargetPOI;
        }
        targetPoint.targetObj = poi;
    }
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = formattedTargetName;
    targetPoint.titleSecond = captionExt;
    targetPoint.zoom = renderView.zoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.values = values;
    targetPoint.localizedNames = names;
    targetPoint.localizedContent = content;
    targetPoint.titleAddress = roadTitle;
    targetPoint.centerMap = centerMap;
    targetPoint.addressFound = isAddressFound;
    
    return targetPoint;
}

- (NSString *)findRoadNameByLat:(double)lat lon:(double)lon
{
    std::shared_ptr<OsmAnd::CachingRoadLocator> _roadLocator;
    _roadLocator.reset(new OsmAnd::CachingRoadLocator(_app.resourcesManager->obfsCollection));
    
    std::shared_ptr<const OsmAnd::Road> road;
    
    const OsmAnd::PointI position31(
                                    OsmAnd::Utilities::get31TileNumberX(lon),
                                    OsmAnd::Utilities::get31TileNumberY(lat));
    
    road = _roadLocator->findNearestRoad(position31,
                                         kMaxRoadDistanceInMeters,
                                         OsmAnd::RoutingDataLevel::Detailed,
                                         [self]
                                         (const std::shared_ptr<const OsmAnd::Road>& road)
                                         {
                                             return road->containsTag(QString("highway")) && road->captions.count() > 0;
                                         });
    
    NSString* localizedTitle;
    NSString* nativeTitle;
    NSString* roadTitle;
    if (road)
    {
        NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
        
        //for (const auto& entry : OsmAnd::rangeOf(road->captions))
        //    NSLog(@"%d=%@", entry.key(), entry.value().toNSString());
        
        if (prefLang)
        {
            const auto mainLanguage = QString::fromNSString(prefLang);
            const auto localizedName = road->getCaptionInLanguage(mainLanguage);
            if (!localizedName.isNull())
                localizedTitle = localizedName.toNSString();
        }
        const auto nativeName = road->getCaptionInNativeLanguage();
        if (!nativeName.isNull())
            nativeTitle = nativeName.toNSString();
    }
    
    if (localizedTitle)
    {
        roadTitle = localizedTitle;
    }
    else if (nativeTitle)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if (settings.settingMapLanguageTranslit)
            roadTitle = OsmAnd::ICU::transliterateToLatin(road->getCaptionInNativeLanguage()).toNSString();
        else
            roadTitle = nativeTitle;
    }
    
    return roadTitle;
}

- (void)goToTargetPointDefault
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    renderView.zoom = kDefaultFavoriteZoomOnShow;
    
    _mainMapAzimuth = 0.0;
    _mainMapEvelationAngle = 90.0;
    _mainMapZoom = kDefaultFavoriteZoomOnShow;
    
    [self targetGoToPoint];
}

-(void)createShadowButton:(SEL)action withLongPressEvent:(SEL)withLongPressEvent topView:(UIView *)topView
{
    if (_shadowButton && [self.view.subviews containsObject:_shadowButton])
        [self destroyShadowButton];
    
    self.shadowButton = [[UIButton alloc] initWithFrame:[self shadowButtonRect]];
    [_shadowButton setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0]];
    [_shadowButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    if (withLongPressEvent) {
        _shadowLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:withLongPressEvent];
        [_shadowButton addGestureRecognizer:_shadowLongPress];
    }
    
    [self.view insertSubview:self.shadowButton belowSubview:topView];
}

-(void)destroyShadowButton
{
    if (_shadowButton)
    {
        [_shadowButton removeFromSuperview];
        if (_shadowLongPress) {
            [_shadowButton removeGestureRecognizer:_shadowLongPress];
            _shadowLongPress = nil;
        }
        self.shadowButton = nil;
    }
}

- (void)shadowTargetPointLongPress:(UILongPressGestureRecognizer*)gesture
{
    if (![self.targetMenuView preHide])
        return;

    if ( gesture.state == UIGestureRecognizerStateEnded )
        [_mapViewController simulateContextMenuPress:gesture];
}

- (void)showTopControls
{
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController showTopControls];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController showTopControls];
}

- (void)hideTopControls
{
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController hideTopControls];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController hideTopControls];
}

-(void)setTopControlsVisible:(BOOL)visible
{
    if (visible)
    {
        [self showTopControls];
        _customStatusBarStyleNeeded = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    else
    {
        [self hideTopControls];
        _customStatusBarStyle = UIStatusBarStyleLightContent;
        _customStatusBarStyleNeeded = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)contextMenuMode
{
    if (_hudViewController == self.browseMapViewController)
        return self.browseMapViewController.contextMenuMode;
    else if (_hudViewController == self.driveModeViewController)
        return self.driveModeViewController.contextMenuMode;
    else
        return NO;
}

- (void)enterContextMenuMode
{
    EOAMapModeButtonType mapModeButtonType;
    switch (_activeTargetType)
    {
        case OATargetGPX:
            mapModeButtonType = EOAMapModeButtonTypeShowMap;
            break;
        case OATargetGPXRoute:
            mapModeButtonType = EOAMapModeButtonTypeNavigate;
            break;
            
        default:
            mapModeButtonType = EOAMapModeButtonRegular;
            break;
    }
    
    if (_hudViewController == self.browseMapViewController)
    {
        self.browseMapViewController.mapModeButtonType = mapModeButtonType;
        [self.browseMapViewController enterContextMenuMode];
    }
    else if (_hudViewController == self.driveModeViewController)
    {
        self.driveModeViewController.mapModeButtonType = mapModeButtonType;
        [self.driveModeViewController enterContextMenuMode];
    }
}

- (void)restoreFromContextMenuMode
{
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController restoreFromContextMenuMode];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController restoreFromContextMenuMode];
}

- (void)showBottomControls:(CGFloat)menuHeight
{
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController showBottomControls:menuHeight];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController showBottomControls:menuHeight];
}

- (void)hideBottomControls:(CGFloat)menuHeight
{
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController hideBottomControls:menuHeight];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController hideBottomControls:menuHeight];
}

-(void)setBottomControlsVisible:(BOOL)visible menuHeight:(CGFloat)menuHeight
{
    if (visible)
        [self showBottomControls:menuHeight];
    else
        [self hideBottomControls:menuHeight];
}

- (void)storeActiveTargetViewControllerState
{
    switch (_activeTargetType)
    {
        case OATargetGPX:
        {
            OAGPXItemViewControllerState *gpxItemViewControllerState = (OAGPXItemViewControllerState *)([((OAGPXItemViewController *)self.targetMenuView.customController) getCurrentState]);
            gpxItemViewControllerState.showFull = self.targetMenuView.showFull;
            gpxItemViewControllerState.showFullScreen = self.targetMenuView.showFullScreen;
            gpxItemViewControllerState.showCurrentTrack = (!_activeTargetObj || ((OAGPX *)_activeTargetObj).gpxFileName.length == 0);
            
            _activeViewControllerState = gpxItemViewControllerState;
            break;
        }

        case OATargetGPXEdit:
        {
            OAGPXEditItemViewControllerState *gpxItemViewControllerState = (OAGPXEditItemViewControllerState *)([((OAGPXEditItemViewController *)self.targetMenuView.customController) getCurrentState]);
            gpxItemViewControllerState.showFullScreen = self.targetMenuView.showFullScreen;
            gpxItemViewControllerState.showCurrentTrack = (!_activeTargetObj || ((OAGPX *)_activeTargetObj).gpxFileName.length == 0);
            
            _activeViewControllerState = gpxItemViewControllerState;
            break;
        }
            
        case OATargetGPXRoute:
        {
            OAGPXRouteViewControllerState *gpxItemViewControllerState = (OAGPXRouteViewControllerState *)([((OAGPXRouteViewController *)self.targetMenuView.customController) getCurrentState]);
            gpxItemViewControllerState.showFullScreen = self.targetMenuView.showFullScreen;
            gpxItemViewControllerState.showCurrentTrack = (!_activeTargetObj || ((OAGPX *)_activeTargetObj).gpxFileName.length == 0);
            
            _activeViewControllerState = gpxItemViewControllerState;
            break;
        }
            
        default:
            break;
    }
}

- (void)restoreActiveTargetMenu
{
    switch (_activeTargetType)
    {
        case OATargetGPX:
            [_mapViewController hideContextPinMarker];
            [self openTargetViewWithGPX:_activeTargetObj pushed:YES];
            break;

        case OATargetGPXEdit:
            [_mapViewController hideContextPinMarker];
            [self openTargetViewWithGPXEdit:_activeTargetObj pushed:YES];
            break;
            
        case OATargetGPXRoute:
            [_mapViewController hideContextPinMarker];
            [[OARootViewController instance].mapPanel openTargetViewWithGPXRoute:YES segmentType:kSegmentRouteWaypoints];
            break;
            
        default:
            break;
    }
}

- (void)resetActiveTargetMenu
{
    if ([self hasGpxActiveTargetType] && _activeTargetObj)
        ((OAGPX *)_activeTargetObj).newGpx = NO;
    
    _activeTargetActive = NO;
    _activeTargetObj = nil;
    _activeTargetType = OATargetNone;
    _activeViewControllerState = nil;

    _targetMenuView.activeTargetType = _activeTargetType;
    
    [self restoreFromContextMenuMode];
}

- (void)onDestinationRemove:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        _targetDestination = nil;
        [_mapViewController hideContextPinMarker];
        [_mapViewController removeDestinationPin:destination.latitude longitude:destination.longitude];
    });
}

- (void)createShade
{
    if (_shadeView)
    {
        [_shadeView removeFromSuperview];
        _shadeView = nil;
    }
    
    _shadeView = [[UIView alloc] initWithFrame:self.view.frame];
    _shadeView.backgroundColor = UIColorFromRGBA(0x00000060);
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _shadeView.alpha = 0.0;
}

- (void)removeShade
{
    [_shadeView removeFromSuperview];
    _shadeView = nil;
}

-(BOOL)gpxModeActive
{
    return (_activeTargetActive &&
        (_activeTargetType == OATargetGPX || _activeTargetType == OATargetGPXEdit || _activeTargetType == OATargetGPXRoute));
}

#pragma mark - OATargetPointViewDelegate

- (void)targetViewEnableMapInteraction
{
    if (self.shadowButton)
        self.shadowButton.hidden = YES;
}

- (void)targetViewDisableMapInteraction
{
    if (self.shadowButton)
        self.shadowButton.hidden = NO;
}

- (void)targetZoomIn
{
    [_mapViewController animatedZoomIn];
}

- (void)targetZoomOut
{
    [_mapViewController animatedZoomOut];
    [_mapViewController calculateMapRuler];
}

-(void)targetPointAddFavorite
{
    if ([_mapViewController hasFavoriteAt:CLLocationCoordinate2DMake(_targetLatitude, _targetLongitude)])
        return;
    
    OAFavoriteViewController *favoriteViewController = [[OAFavoriteViewController alloc] initWithLocation:self.targetMenuView.targetPoint.location andTitle:self.targetMenuView.targetPoint.title];
    
    UIColor* color = [UIColor colorWithRed:favoriteViewController.favorite.favorite->getColor().r/255.0 green:favoriteViewController.favorite.favorite->getColor().g/255.0 blue:favoriteViewController.favorite.favorite->getColor().b/255.0 alpha:1.0];
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    self.targetMenuView.targetPoint.icon = [UIImage imageNamed:favCol.iconName];
    self.targetMenuView.targetPoint.type = OATargetFavorite;
    
    [favoriteViewController activateEditing];
    
    [self.targetMenuView setCustomViewController:favoriteViewController needFullMenu:YES];
    [self.targetMenuView updateTargetPointType:OATargetFavorite];
}

-(void)targetPointShare
{
}

-(void)targetPointDirection
{
    if (_targetDestination)
    {
        if (self.targetMenuView.targetPoint.type != OATargetDestination && self.targetMenuView.targetPoint.type != OATargetParking)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            [[OADestinationsHelper instance] addHistoryItem:_targetDestination];
            [[OADestinationsHelper instance] removeDestination:_targetDestination];
        });
    }
    else
    {
        OADestination *destination = [[OADestination alloc] initWithDesc:_formattedTargetName latitude:_targetLatitude longitude:_targetLongitude];

        UIColor *color = [_destinationViewController addDestination:destination];
        if (color)
        {
            [_mapViewController addDestinationPin:destination.markerResourceName color:destination.color latitude:_targetLatitude longitude:_targetLongitude];
            [_mapViewController hideContextPinMarker];
            [[OADestinationsHelper instance] moveDestinationOnTop:destination wasSelected:NO];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_add_destination") message:OALocalizedString(@"cannot_add_marker_desc") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil
              ] show];
        }
    }
    
    [self hideTargetPointMenu];
}

- (void)targetPointParking
{
    OAParkingViewController *parking = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(_targetLatitude, _targetLongitude)];
    parking.parkingDelegate = self;
    
    [self.targetMenuView setCustomViewController:parking needFullMenu:YES];
    [self.targetMenuView updateTargetPointType:OATargetParking];
}

- (void)targetPointAddWaypoint
{
    if ([_mapViewController hasWptAt:CLLocationCoordinate2DMake(_targetLatitude, _targetLongitude)])
        return;
    
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    for (NSString *fileName in settings.mapSettingVisibleGpx)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            [names addObject:[fileName stringByDeletingPathExtension]];
            [paths addObject:path];
        }
    }
    
    // Ask for track where to add waypoint
    if (names.count > 0)
    {
        if ([self hasGpxActiveTargetType])
        {
            if (_activeTargetObj)
            {
                OAGPX *gpx = (OAGPX *)_activeTargetObj;
                NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFileName];
                [self targetPointAddWaypoint:path];
            }
            else
            {
                [self targetPointAddWaypoint:nil];
            }
            return;
        }
        
        [names insertObject:OALocalizedString(@"gpx_curr_new_track") atIndex:0];
        [paths insertObject:@"" atIndex:0];
        
        if (names.count > 5)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"gpx_select_track") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")] otherButtonItems: nil];
            
            for (int i = 0; i < names.count; i++)
            {
                NSString *name = names[i];
                [alert addButtonItem:[RIButtonItem itemWithLabel:name action:^{
                    NSString *gpxFileName = paths[i];
                    if (gpxFileName.length == 0)
                        gpxFileName = nil;
                    
                    [self targetPointAddWaypoint:gpxFileName];
                }]];
            }
            [alert show];
        }
        else
        {
            NSMutableArray *images = [NSMutableArray array];
            for (int i = 0; i < names.count; i++)
                [images addObject:@"icon_info"];
            
            [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_select_track")
                                    message:nil
                                cancelTitle:OALocalizedString(@"shared_string_cancel")
                                otherTitles:names
                                  otherDesc:nil
                                otherImages:images
                                 completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                     if (!cancelled)
                                     {
                                         NSInteger trackId = buttonIndex;
                                         NSString *gpxFileName = paths[trackId];
                                         if (gpxFileName.length == 0)
                                             gpxFileName = nil;
                                         
                                         [self targetPointAddWaypoint:gpxFileName];
                                     }
                                 }];
        }
        
    }
    else
    {
        [self targetPointAddWaypoint:nil];
    }
}

- (void)targetPointAddWaypoint:(NSString *)gpxFileName
{
    OAGPXWptViewController *wptViewController = [[OAGPXWptViewController alloc] initWithLocation:self.targetMenuView.targetPoint.location andTitle:self.targetMenuView.targetPoint.title gpxFileName:gpxFileName];
    
    wptViewController.mapViewController = self.mapViewController;
    wptViewController.wptDelegate = self;
    
    [_mapViewController addNewWpt:wptViewController.wpt.point gpxFileName:gpxFileName];
    wptViewController.wpt.groups = _mapViewController.foundWptGroups;

    UIColor* color = wptViewController.wpt.color;
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    
    self.targetMenuView.targetPoint.type = OATargetWpt;
    self.targetMenuView.targetPoint.icon = [UIImage imageNamed:favCol.iconName];
    self.targetMenuView.targetPoint.targetObj = wptViewController.wpt;
    
    [wptViewController activateEditing];
    
    [self.targetMenuView setCustomViewController:wptViewController needFullMenu:YES];
    [self.targetMenuView updateTargetPointType:OATargetWpt];
    
    if (_activeTargetType == OATargetGPXEdit)
        wptViewController.navBarBackground.backgroundColor = UIColorFromRGB(0x4caf50);

    if (!gpxFileName && ![OAAppSettings sharedManager].mapSettingShowRecordingTrack)
    {
        [OAAppSettings sharedManager].mapSettingShowRecordingTrack = YES;
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
}

-(void)targetHideContextPinMarker
{
    [_mapViewController hideContextPinMarker];
}

-(void)targetHide
{
    [_mapViewController hideContextPinMarker];
    [self hideTargetPointMenu];
}

-(void)targetHideMenu:(CGFloat)animationDuration backButtonClicked:(BOOL)backButtonClicked
{
    if (backButtonClicked)
    {
        if (_activeTargetType != OATargetNone && !_activeTargetActive)
            animationDuration = .1;
        
        [self hideTargetPointMenuAndPopup:animationDuration];
    }
    else
    {
        [self hideTargetPointMenu:animationDuration];
    }
}

-(void)targetGoToPoint
{
    OsmAnd::LatLon latLon(_targetLatitude, _targetLongitude);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);

    [_mapViewController correctPosition:point originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31] leftInset:([self.targetMenuView isLandscape] ? kInfoViewLanscapeWidth : 0.0) bottomInset:([self.targetMenuView isLandscape] ? 0.0 : self.targetMenuView.frame.size.height) centerBBox:(_targetMode == EOATargetBBOX) animated:YES];

}

-(void)targetGoToGPX
{
    if (_activeTargetObj)
        [self displayGpxOnMap:_activeTargetObj];
    else
        [self displayGpxOnMap:[[OASavingTrackHelper sharedInstance] getCurrentGPX]];
}

-(void)targetGoToGPXRoute
{
    [self openTargetViewWithGPXRoute:_activeTargetObj pushed:YES];
}

-(void)targetViewSizeChanged:(CGRect)newFrame animated:(BOOL)animated
{
    if (self.targetMenuView.targetPoint.type == OATargetGPX || self.targetMenuView.targetPoint.type == OATargetGPXEdit)
        return;
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    [_mapViewController correctPosition:targetPoint31 originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31] leftInset:([self.targetMenuView isLandscape] ? kInfoViewLanscapeWidth : 0.0) bottomInset:([self.targetMenuView isLandscape] ? 0.0 : newFrame.size.height) centerBBox:(_targetMode == EOATargetBBOX) animated:animated];
}

-(void)showTargetPointMenu:(BOOL)saveMapState showFullMenu:(BOOL)showFullMenu
{
    [self showTargetPointMenu:saveMapState showFullMenu:showFullMenu onComplete:nil];
}

-(void)showTargetPointMenu:(BOOL)saveMapState showFullMenu:(BOOL)showFullMenu onComplete:(void (^)(void))onComplete
{
    if (self.targetMultiMenuView.superview)
        [self.targetMultiMenuView hide:YES duration:.2 onComplete:nil];

    if (_activeTargetActive)
    {
        [self storeActiveTargetViewControllerState];
        _activeTargetActive = NO;
        BOOL activeTargetChildPushed = _activeTargetChildPushed;
        _activeTargetChildPushed = NO;
        
        [self hideTargetPointMenu:.1 onComplete:^{
            
            [self showTargetPointMenu:saveMapState showFullMenu:showFullMenu onComplete:onComplete];
            _activeTargetChildPushed = activeTargetChildPushed;
            
        } hideActiveTarget:YES mapGestureAction:NO];
        
        return;
    }
    
    if (_mapSettings)
        [self closeMapSettings];
    
    if (saveMapState)
        [self saveMapStateNoRestore];
    
    _mapStateSaved = saveMapState;
    
    switch (_targetMenuView.targetPoint.type)
    {
        case OATargetFavorite:
        {
            OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
            for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                int favLon = (int)(OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) * 10000.0);
                int favLat = (int)(OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) * 10000.0);
                
                if ((int)(_targetLatitude * 10000.0) == favLat && (int)(_targetLongitude * 10000.0) == favLon)
                {
                    item.favorite = favLoc;
                    break;
                }
            }
            
            [self.targetMenuView doInit:showFullMenu];
            
            OAFavoriteViewController *favoriteViewController = [[OAFavoriteViewController alloc] initWithItem:item];
            
            [self.targetMenuView setCustomViewController:favoriteViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];
            
            break;
        }
            
        case OATargetDestination:
        {
            [self.targetMenuView doInit:showFullMenu];
            OATargetDestinationViewController *destViewController = [[OATargetDestinationViewController alloc] initWithDestination:self.targetMenuView.targetPoint.targetObj];
            
            [self.targetMenuView setCustomViewController:destViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];
            
            break;
        }

        case OATargetHistoryItem:
        {
            [self.targetMenuView doInit:showFullMenu];
            OATargetHistoryItemViewController *hItemViewController = [[OATargetHistoryItemViewController alloc] initWithHistoryItem:self.targetMenuView.targetPoint.targetObj];
            
            [self.targetMenuView setCustomViewController:hItemViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];
            
            break;
        }
            
        case OATargetParking:
        {
            [self.targetMenuView doInit:showFullMenu];
            
            OAParkingViewController *parking;
            if (self.targetMenuView.targetPoint.targetObj)
                parking = [[OAParkingViewController alloc] initWithParking:self.targetMenuView.targetPoint.targetObj];
            else
                parking = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(_targetLatitude, _targetLongitude)];
            
            parking.parkingDelegate = self;
            
            [self.targetMenuView setCustomViewController:parking needFullMenu:NO];
            [self.targetMenuView prepareNoInit];

            break;
        }

        case OATargetPOI:
        {
            [self.targetMenuView doInit:showFullMenu];
            
            OAPOIViewController *poiViewController = [[OAPOIViewController alloc] initWithPOI:self.targetMenuView.targetPoint.targetObj];

            [self.targetMenuView setCustomViewController:poiViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];
            
            break;
        }
        
        case OATargetWiki:
        {
            NSString *contentLocale = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            if (!contentLocale)
                contentLocale = [OAUtilities currentLang];
            
            NSString *content = [self.targetMenuView.targetPoint.localizedContent objectForKey:contentLocale];
            if (!content)
            {
                contentLocale = @"";
                content = [self.targetMenuView.targetPoint.localizedContent objectForKey:contentLocale];
            }
            if (!content && self.targetMenuView.targetPoint.localizedContent.count > 0)
            {
                contentLocale = self.targetMenuView.targetPoint.localizedContent.allKeys[0];
                content = [self.targetMenuView.targetPoint.localizedContent objectForKey:contentLocale];
            }
            
            if (content)
            {
                [self.targetMenuView doInit:showFullMenu];
                
                OAWikiMenuViewController *wiki = [[OAWikiMenuViewController alloc] initWithPOI:self.targetMenuView.targetPoint.targetObj content:content];
                wiki.menuDelegate = self;
                
                [self.targetMenuView setCustomViewController:wiki needFullMenu:NO];
                [self.targetMenuView prepareNoInit];
            }
            else
            {
                [self.targetMenuView prepare];
            }

            break;
        }
            
        case OATargetWpt:
        {
            [self.targetMenuView doInit:showFullMenu];
            
            OAGPXWptViewController *wptViewController;
            if (_activeTargetType == OATargetGPXEdit)
            {
                wptViewController = [[OAGPXEditWptViewController alloc] initWithItem:self.targetMenuView.targetPoint.targetObj];
                [wptViewController activateEditing];
            }
            else
            {
                wptViewController = [[OAGPXWptViewController alloc] initWithItem:self.targetMenuView.targetPoint.targetObj];
            }
            
            wptViewController.mapViewController = self.mapViewController;
            wptViewController.wptDelegate = self;
            
            [self.targetMenuView setCustomViewController:wptViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];

            break;
        }
            
        case OATargetGPX:
        {
            OAGPXItemViewControllerState *state = _activeViewControllerState ? (OAGPXItemViewControllerState *)_activeViewControllerState : nil;
            BOOL showFull = (state && state.showFull) || (!state && showFullMenu);
            BOOL showFullScreen = (state && state.showFullScreen);
            [self.targetMenuView doInit:showFull showFullScreen:showFullScreen];
            
            OAGPXItemViewController *gpxViewController;
            if (self.targetMenuView.targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        gpxViewController = [[OAGPXItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        gpxViewController = [[OAGPXItemViewController alloc] initWithGPXItem:self.targetMenuView.targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    gpxViewController = [[OAGPXItemViewController alloc] initWithGPXItem:self.targetMenuView.targetPoint.targetObj];
                }
            }
            else
            {
                gpxViewController = [[OAGPXItemViewController alloc] initWithCurrentGPXItem];
                self.targetMenuView.targetPoint.targetObj = gpxViewController.gpx;
            }
            
            [self.targetMenuView setCustomViewController:gpxViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];

            break;
        }
            
        case OATargetGPXEdit:
        {
            OAGPXEditItemViewControllerState *state = _activeViewControllerState ? (OAGPXEditItemViewControllerState *)_activeViewControllerState : nil;
            BOOL showFull = (state && state.showFullScreen) || (!state && showFullMenu);
            [self.targetMenuView doInit:showFull showFullScreen:showFull];
            
            OAGPXEditItemViewController *gpxViewController;
            if (self.targetMenuView.targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        gpxViewController = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        gpxViewController = [[OAGPXEditItemViewController alloc] initWithGPXItem:self.targetMenuView.targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    gpxViewController = [[OAGPXEditItemViewController alloc] initWithGPXItem:self.targetMenuView.targetPoint.targetObj];
                }
            }
            else
            {
                gpxViewController = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem];
                self.targetMenuView.targetPoint.targetObj = gpxViewController.gpx;
            }
            
            [self.targetMenuView setCustomViewController:gpxViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];

            break;
        }
            
        case OATargetGPXRoute:
        {
            OAGPXRouteViewControllerState *state = _activeViewControllerState ? (OAGPXRouteViewControllerState *)_activeViewControllerState : nil;
            OAGpxRouteSegmentType segmentType = (OAGpxRouteSegmentType)_targetMenuView.targetPoint.segmentIndex;
            BOOL showFull = (state && state.showFullScreen) || (!state && segmentType == kSegmentRouteWaypoints);
            [self.targetMenuView doInit:showFull showFullScreen:showFull];

            OAGPXRouteViewController *gpxViewController;
            if (state)
            {
                gpxViewController = [[OAGPXRouteViewController alloc] initWithCtrlState:state];
            }
            else
            {
                gpxViewController = [[OAGPXRouteViewController alloc] initWithSegmentType:segmentType];
            }
            
            [self.targetMenuView setCustomViewController:gpxViewController needFullMenu:NO];
            [self.targetMenuView prepareNoInit];

            break;
        }
            
        default:
        {
            [self.targetMenuView prepare];
        }
    }
    
    CGRect frame = self.targetMenuView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    self.targetMenuView.frame = frame;
    
    [self.targetMenuView.layer removeAllAnimations];
    if ([self.view.subviews containsObject:self.targetMenuView])
        [self.targetMenuView removeFromSuperview];
    
    [self.view addSubview:self.targetMenuView];
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    [_mapViewController correctPosition:targetPoint31 originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31] leftInset:([self.targetMenuView isLandscape] ? kInfoViewLanscapeWidth : 0.0) bottomInset:([self.targetMenuView isLandscape] ? 0.0 : frame.size.height) centerBBox:(_targetMode == EOATargetBBOX) animated:YES];
    
    if (onComplete)
        onComplete();
    
    self.sidePanelController.recognizesPanGesture = NO;
    [self.targetMenuView show:YES onComplete:^{
        self.sidePanelController.recognizesPanGesture = NO;
    }];
}

-(void)showMultiPointMenu:(NSArray<OATargetPoint *> *)points onComplete:(void (^)(void))onComplete
{
    if (_mapSettings)
        [self closeMapSettings];
    
    if (self.targetMenuView.superview)
        [self hideTargetPointMenu];
    
    CGRect frame = self.targetMultiMenuView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    self.targetMultiMenuView.frame = frame;
    
    [self.targetMultiMenuView.layer removeAllAnimations];
    if ([self.view.subviews containsObject:self.targetMultiMenuView])
        [self.targetMultiMenuView removeFromSuperview];
    
    [self.targetMultiMenuView setTargetPoints:points];
    
    [self.view addSubview:self.targetMultiMenuView];
    
    if (onComplete)
        onComplete();
    
    self.sidePanelController.recognizesPanGesture = NO;
    [self.targetMultiMenuView show:YES onComplete:^{
        self.sidePanelController.recognizesPanGesture = NO;
    }];
}

- (void)targetHideMenuByMapGesture
{
    [self hideTargetPointMenu:.2 onComplete:nil hideActiveTarget:NO mapGestureAction:YES];
}

-(void)targetSetTopControlsVisible:(BOOL)visible
{
    [self setTopControlsVisible:visible];
}

-(void)targetSetBottomControlsVisible:(BOOL)visible menuHeight:(CGFloat)menuHeight
{
    [self setBottomControlsVisible:visible menuHeight:menuHeight];
}

-(void)hideTargetPointMenu
{
    [self hideTargetPointMenu:.2 onComplete:nil];
}

-(void)hideTargetPointMenu:(CGFloat)animationDuration
{
    [self hideTargetPointMenu:animationDuration onComplete:nil];
}

-(void)hideTargetPointMenu:(CGFloat)animationDuration onComplete:(void (^)(void))onComplete
{
    [self hideTargetPointMenu:animationDuration onComplete:onComplete hideActiveTarget:NO mapGestureAction:NO];
}

-(void)hideTargetPointMenu:(CGFloat)animationDuration onComplete:(void (^)(void))onComplete hideActiveTarget:(BOOL)hideActiveTarget mapGestureAction:(BOOL)mapGestureAction
{
    if (self.targetMultiMenuView.superview)
    {
        [self.targetMultiMenuView hide:YES duration:animationDuration onComplete:nil];
        return;
    }
    
    if (mapGestureAction && self.targetMenuView.targetPoint.type == OATargetGPX)
    {
        [self.targetMenuView requestHeaderOnlyMode];
        return;
    }
    
    if (![self.targetMenuView preHide])
        return;
    
    if (!hideActiveTarget)
    {
        if (_mapStateSaved)
            [self restoreMapAfterReuseAnimated];
        
        _mapStateSaved = NO;
    }
    
    [self destroyShadowButton];
    
    if (_activeTargetType != OATargetNone && !_activeTargetActive && !_activeTargetChildPushed && !hideActiveTarget && animationDuration > .1)
        animationDuration = .1;
    
    [self.targetMenuView hide:YES duration:animationDuration onComplete:^{
        
        if (_activeTargetType != OATargetNone)
        {
            if (_activeTargetActive || _activeTargetChildPushed)
            {
                [self resetActiveTargetMenu];
                _activeTargetChildPushed = NO;
            }
            else if (!hideActiveTarget)
            {
                [self restoreActiveTargetMenu];
            }
        }
        
        if (onComplete)
            onComplete();
        
    }];
    
    [self showTopControls];
    _customStatusBarStyleNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];

    self.sidePanelController.recognizesPanGesture = NO; //YES;
}

-(void)hideTargetPointMenuAndPopup:(CGFloat)animationDuration
{
    if (self.targetMultiMenuView.superview)
    {
        [self.targetMultiMenuView hide:YES duration:animationDuration onComplete:nil];
        return;
    }

    if (![self.targetMenuView preHide])
        return;

    if (_mapStateSaved)
        [self restoreMapAfterReuseAnimated];
    
    _mapStateSaved = NO;
    
    [self destroyShadowButton];
    
    if (_activeTargetType == OATargetNone || _activeTargetActive)
    {
        BOOL popped;
        switch (self.targetMenuView.targetPoint.type)
        {
            case OATargetGPX:
            case OATargetGPXEdit:
                if ([self hasGpxActiveTargetType] && _activeTargetObj)
                    ((OAGPX *)_activeTargetObj).newGpx = NO;
                popped = [OAGPXListViewController popToParent];
                break;
                
            case OATargetGPXRoute:
                popped = [OAGPXListViewController popToParent];
                break;
                
            case OATargetFavorite:
                popped = [OAFavoriteListViewController popToParent];
                break;

            default:
                popped = NO;
                break;
        }

        if (!popped)
            [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self.targetMenuView hide:YES duration:animationDuration onComplete:^{
        
        if (_activeTargetType != OATargetNone)
        {
            if (_activeTargetActive)
                [self resetActiveTargetMenu];
            else
                [self restoreActiveTargetMenu];

            _activeTargetChildPushed = NO;
        }
        
    }];
    
    [self showTopControls];
    _customStatusBarStyleNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.sidePanelController.recognizesPanGesture = NO; //YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.targetMenuView.superview)
        [self.targetMenuView prepareForRotation:toInterfaceOrientation];
}

- (void)openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed
{
    OsmAnd::LatLon latLon = item.favorite->getLatLon();
    NSString *caption = item.favorite->getTitle().toNSString();

    UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    UIImage *icon = [UIImage imageNamed:favCol.iconName];

    [self openTargetViewWithFavorite:latLon.latitude longitude:latLon.longitude caption:caption icon:icon pushed:pushed];
}

- (void)openTargetViewWithFavorite:(double)lat longitude:(double)lon caption:(NSString *)caption icon:(UIImage *)icon pushed:(BOOL)pushed
{
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    targetPoint.type = OATargetFavorite;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = _formattedTargetName;
    targetPoint.zoom = renderView.zoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
        if (pushed)
            [self goToTargetPointDefault];
        else
            [self targetGoToPoint];
    }];
}

- (void)openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed
{
    [self openTargetViewWithHistoryItem:item pushed:pushed showFullMenu:NO];
}

- (void)openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu
{
    double lat = item.latitude;
    double lon = item.longitude;
    
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = item.name;    
    UIImage *icon = [item icon];
    
    targetPoint.type = OATargetHistoryItem;

    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = [self findRoadNameByLat:lat lon:lon];
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = caption;
    targetPoint.titleAddress = _formattedTargetName;
    targetPoint.zoom = renderView.zoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = item;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:YES showFullMenu:showFullMenu onComplete:^{
        if (pushed)
            [self goToTargetPointDefault];
        else
            [self targetGoToPoint];
    }];
}

- (void)openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed
{
    [self openTargetViewWithWpt:item pushed:pushed showFullMenu:YES];
}

- (void)openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu
{
    double lat = item.point.position.latitude;
    double lon = item.point.position.longitude;
    
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    if ([_mapViewController findWpt:item.point.position])
    {
        item.point = _mapViewController.foundWpt;
        item.groups = _mapViewController.foundWptGroups;
    }
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = item.point.name;
    
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:item.color];
    UIImage *icon = [UIImage imageNamed:favCol.iconName];
    
    targetPoint.type = OATargetWpt;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = _formattedTargetName;
    targetPoint.zoom = renderView.zoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = item;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    if (pushed && _activeTargetActive && [self hasGpxActiveTargetType])
        _activeTargetChildPushed = YES;

    [self showTargetPointMenu:YES showFullMenu:showFullMenu onComplete:^{
        if (pushed)
            [self goToTargetPointDefault];
        else
            [self targetGoToPoint];
    }];
}

- (void)openTargetViewWithGPX:(OAGPX *)item pushed:(BOOL)pushed
{
    BOOL showCurrentTrack = NO;
    if (item == nil)
    {
        item = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
        item.gpxTitle = OALocalizedString(@"track_recording_name");
        showCurrentTrack = YES;
    }
    
    [_mapViewController hideContextPinMarker];

    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = [item getNiceTitle];
    
    UIImage *icon = [UIImage imageNamed:@"icon_info"];
    
    targetPoint.type = OATargetGPX;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    
    if (_activeTargetType != OATargetGPX)
        [self displayGpxOnMap:item];
    
    if (item.bounds.center.latitude == DBL_MAX)
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
        targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        _targetLatitude = latLon.latitude;
        _targetLongitude = latLon.longitude;
    }
    else
    {
        targetPoint.location = CLLocationCoordinate2DMake(item.bounds.center.latitude, item.bounds.center.longitude);
    }
    
    targetPoint.title = _formattedTargetName;
    targetPoint.zoom = _targetZoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = NO;
    if (!showCurrentTrack)
        targetPoint.targetObj = item;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    
    _targetMenuView.activeTargetType = _activeTargetType;
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:YES showFullMenu:!item.newGpx onComplete:^{
        [self enterContextMenuMode];
        _activeTargetActive = YES;
    }];
}

- (void)openTargetViewWithGPXEdit:(OAGPX *)item pushed:(BOOL)pushed
{
    BOOL showCurrentTrack = NO;
    if (item == nil)
    {
        item = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
        item.gpxTitle = OALocalizedString(@"track_recording_name");
        showCurrentTrack = YES;
    }
    
    [_mapViewController hideContextPinMarker];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = [item getNiceTitle];
    
    UIImage *icon = [UIImage imageNamed:@"icon_info"];
    
    targetPoint.type = OATargetGPXEdit;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    
    if (_activeTargetType != OATargetGPXEdit)
        [self displayGpxOnMap:item];
    
    if (item.bounds.center.latitude == DBL_MAX)
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
        targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        _targetLatitude = latLon.latitude;
        _targetLongitude = latLon.longitude;
    }
    else
    {
        targetPoint.location = CLLocationCoordinate2DMake(item.bounds.center.latitude, item.bounds.center.longitude);
    }
    
    targetPoint.title = _formattedTargetName;
    targetPoint.zoom = _targetZoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = NO;
    if (!showCurrentTrack)
        targetPoint.targetObj = item;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    
    _targetMenuView.activeTargetType = _activeTargetType;
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self enterContextMenuMode];
    [self showTargetPointMenu:YES showFullMenu:!item.newGpx onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void)openTargetViewWithGPXRoute:(BOOL)pushed
{
    [self openTargetViewWithGPXRoute:nil pushed:pushed segmentType:kSegmentRoute];
}

- (void)openTargetViewWithGPXRoute:(BOOL)pushed segmentType:(OAGpxRouteSegmentType)segmentType
{
    [self openTargetViewWithGPXRoute:nil pushed:pushed segmentType:segmentType];
}

- (void)openTargetViewWithGPXRoute:(OAGPX *)item pushed:(BOOL)pushed
{
    [self openTargetViewWithGPXRoute:item pushed:pushed segmentType:kSegmentRoute];
}

- (void)openTargetViewWithGPXRoute:(OAGPX *)item pushed:(BOOL)pushed segmentType:(OAGpxRouteSegmentType)segmentType
{
    if (![[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TripPlanning])
    {
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_TripPlanning];
        return;
    }

    [_mapViewController hideContextPinMarker];
 
    BOOL useCurrentRoute = (item == nil);
    if (useCurrentRoute)
        item = [OAGPXRouter sharedInstance].gpx;
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = [item getNiceTitle];
    
    UIImage *icon = [UIImage imageNamed:@"ic_route_modebg.jpg"];
    
    targetPoint.type = OATargetGPXRoute;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    
    if (item.bounds.center.latitude == DBL_MAX)
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
        targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        _targetLatitude = latLon.latitude;
        _targetLongitude = latLon.longitude;
    }
    else
    {
        targetPoint.location = CLLocationCoordinate2DMake(item.bounds.center.latitude, item.bounds.center.longitude);
    }
    
    targetPoint.title = _formattedTargetName;
    targetPoint.zoom = _targetZoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = NO;
    targetPoint.targetObj = item;
    targetPoint.segmentIndex = segmentType;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    
    _targetMenuView.activeTargetType = _activeTargetType;
    [_targetMenuView setTargetPoint:targetPoint];
    
    if (!useCurrentRoute)
        [[OAGPXRouter sharedInstance] setRouteWithGpx:item];
    
    [self enterContextMenuMode];
    [self showTargetPointMenu:YES showFullMenu:!item.newGpx onComplete:^{
        _activeTargetActive = YES;
        [self displayGpxOnMap:item];
    }];
}

- (void)openTargetViewWithDestination:(OADestination *)destination
{
    [self destinationViewMoveTo:destination];
}

- (void)displayGpxOnMap:(OAGPX *)item
{
    if (item.bounds.topLeft.latitude == DBL_MAX)
        return;
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    CGSize screenBBox = CGSizeMake(DeviceScreenWidth - ([self.targetMenuView isLandscape] ? kInfoViewLanscapeWidth : 0.0), DeviceScreenHeight - ([self.targetMenuView isLandscape] ? 0.0 : 233.0));
    _targetZoom = [self getZoomForBounds:item.bounds mapSize:screenBBox];
    _targetMode = (_targetZoom > 0.0 ? EOATargetBBOX : EOATargetPoint);
    
    if (_targetMode == EOATargetBBOX)
    {
        _targetLatitude = item.bounds.bottomRight.latitude;
        _targetLongitude = item.bounds.topLeft.longitude;
    }
    else
    {
        _targetLatitude = item.bounds.center.latitude;
        _targetLongitude = item.bounds.center.longitude;
    }
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(item.bounds.center.latitude, item.bounds.center.longitude))];
    [_mapViewController goToPosition:targetPoint31
                             andZoom:(_targetMode == EOATargetBBOX ? _targetZoom : kDefaultFavoriteZoomOnShow)
                            animated:NO];
    
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    
    OsmAnd::LatLon latLon(item.bounds.center.latitude, item.bounds.center.longitude);
    _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
    _mainMapZoom = _targetZoom;
    
    if (self.targetMenuView.superview && !self.targetMenuView.showFullScreen)
    {
        CGRect frame = self.targetMenuView.frame;
        
        Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
        [_mapViewController correctPosition:targetPoint31 originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31] leftInset:([self.targetMenuView isLandscape] ? kInfoViewLanscapeWidth : 0.0) bottomInset:([self.targetMenuView isLandscape] ? 0.0 : frame.size.height) centerBBox:(_targetMode == EOATargetBBOX) animated:NO];
    }
}

- (BOOL)goToMyLocationIfInArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight
{
    BOOL res = NO;
    
    CLLocation *myLoc = _app.locationServices.lastKnownLocation;
    if (myLoc && topLeft.latitude != DBL_MAX)
    {
        CLLocationCoordinate2D my = myLoc.coordinate;

        OsmAnd::PointI myI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(my.latitude, my.longitude));
        OsmAnd::PointI topLeftI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLeft.latitude, topLeft.longitude));
        OsmAnd::PointI bottomRightI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomRight.latitude, bottomRight.longitude));
        
        if (topLeftI.x < myI.x &&
            topLeftI.y < myI.y &&
            bottomRightI.x > myI.x &&
            bottomRightI.y > myI.y)
        {
            OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
            
            _targetZoom = kDefaultFavoriteZoom;
            _targetMode = EOATargetPoint;
            
            _targetLatitude = my.latitude;
            _targetLongitude = my.longitude;
            
            Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(my.latitude, my.longitude))];
            [_mapViewController goToPosition:targetPoint31
                                     andZoom:(_targetMode == EOATargetBBOX ? _targetZoom : kDefaultFavoriteZoomOnShow)
                                    animated:NO];
            
            renderView.azimuth = 0.0;
            renderView.elevationAngle = 90.0;
            
            OsmAnd::LatLon latLon(my.latitude, my.longitude);
            _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
            _mainMapZoom = _targetZoom;
            
            res = YES;
        }
    }
    
    return res;
}

- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight zoom:(float)zoom
{
    OAGpxBounds bounds;
    bounds.topLeft = topLeft;
    bounds.bottomRight = bottomRight;
    bounds.center.latitude = bottomRight.latitude / 2.0 + topLeft.latitude / 2.0;
    bounds.center.longitude = bottomRight.longitude / 2.0 + topLeft.longitude / 2.0;
    
    if (bounds.topLeft.latitude == DBL_MAX)
        return;
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    CGSize screenBBox = CGSizeMake(DeviceScreenWidth, DeviceScreenHeight);
    _targetZoom = (zoom <= 0 ? [self getZoomForBounds:bounds mapSize:screenBBox] : zoom);
    _targetMode = (_targetZoom > 0.0 ? EOATargetBBOX : EOATargetPoint);
    
    _targetLatitude = bounds.bottomRight.latitude;
    _targetLongitude = bounds.topLeft.longitude;
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bounds.center.latitude, bounds.center.longitude))];
    [_mapViewController goToPosition:targetPoint31
                             andZoom:(_targetMode == EOATargetBBOX ? _targetZoom : kDefaultFavoriteZoomOnShow)
                            animated:NO];
    
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    
    OsmAnd::LatLon latLon(bounds.center.latitude, bounds.center.longitude);
    _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
    _mainMapZoom = _targetZoom;
}

- (void)showDestinations
{
    if (_hudViewController == self.browseMapViewController)
        [self.browseMapViewController showDestinations];
    else if (_hudViewController == self.driveModeViewController)
        [self.driveModeViewController showDestinations];
}

- (void)showCards
{
    [OAFirebaseHelper logEvent:@"destinations_open"];

    _destinationViewController.navBarHidden = [OADestinationsHelper instance].sortedDestinations.count > 0;
    [self showDestinations];
    [_destinationViewController updateFrame:NO];
    [self openDestinationCardsView];
}

#pragma mark - OAParkingDelegate

- (void)addParking:(OAParkingViewController *)sender
{
    OADestination *destination = [[OADestination alloc] initWithDesc:_formattedTargetName latitude:sender.coord.latitude longitude:sender.coord.longitude];
    
    destination.parking = YES;
    destination.carPickupDateEnabled = sender.timeLimitActive;
    if (sender.timeLimitActive)
        destination.carPickupDate = sender.date;
    else
        destination.carPickupDate = nil;
    
    UIColor *color = [_destinationViewController addDestination:destination];
    if (color)
    {
        [_mapViewController addDestinationPin:destination.markerResourceName color:destination.color latitude:_targetLatitude longitude:_targetLongitude];
        
        if (sender.timeLimitActive && sender.addToCalActive)
            [OADestinationsHelper addParkingReminderToCalendar:destination];
        
        [_mapViewController hideContextPinMarker];
        [self hideTargetPointMenu];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_add_marker") message:OALocalizedString(@"cannot_add_marker_desc") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil
         ] show];
    }
}

- (void)saveParking:(OAParkingViewController *)sender parking:(OADestination *)parking
{
    parking.carPickupDateEnabled = sender.timeLimitActive;
    if (sender.timeLimitActive)
        parking.carPickupDate = sender.date;
    else
        parking.carPickupDate = nil;
    
    if (parking.eventIdentifier)
        [OADestinationsHelper removeParkingReminderFromCalendar:parking];
    
    if (sender.timeLimitActive && sender.addToCalActive)
        [OADestinationsHelper addParkingReminderToCalendar:parking];
    
    [_destinationViewController updateDestinations];
    [self hideTargetPointMenu];
}

- (void)cancelParking:(OAParkingViewController *)sender
{
    [self hideTargetPointMenu];
}

#pragma mark - OAGPXWptViewControllerDelegate

- (void) changedWptItem
{
    [self.targetMenuView applyTargetObjectChanges];
}

#pragma mark - OAWikiMenuDelegate

- (void)openWiki:(OAWikiMenuViewController *)sender
{
    OAWikiWebViewController *wikiWeb = [[OAWikiWebViewController alloc] initWithLocalizedContent:self.targetMenuView.targetPoint.localizedContent localizedNames:self.targetMenuView.targetPoint.localizedNames];
    [self.navigationController pushViewController:wikiWeb animated:YES];
}

#pragma mark - OADestinationViewControllerProtocol

- (void)destinationsAdded
{
    [self showDestinations];
}

- (void)openDestinationCardsView
{
    OADestinationCardsViewController *cardsController = [OADestinationCardsViewController sharedInstance];
    
    if (!cardsController.view.superview)
    {
        [self hideTargetPointMenu];

        CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height;
        CGFloat h = DeviceScreenHeight - y;
    
        cardsController.view.frame = CGRectMake(0.0, y - h, DeviceScreenWidth, h);
        
        [_hudViewController addChildViewController:cardsController];
        
        [self createShade];
        
        [_hudViewController.view insertSubview:_shadeView belowSubview:_destinationViewController.view];
        
        [_hudViewController.view insertSubview:cardsController.view belowSubview:_destinationViewController.view];
        
        if (_destinationViewController)
            [self.destinationViewController updateCloseButton];
        
        [UIView animateWithDuration:.25 animations:^{
            cardsController.view.frame = CGRectMake(0.0, y, DeviceScreenWidth, h);
            _shadeView.alpha = 1.0;
        }];
    }
}

- (void)hideDestinationCardsView
{
    [self hideDestinationCardsViewAnimated:YES];
}

- (void)hideDestinationCardsViewAnimated:(BOOL)animated
{
    OADestinationCardsViewController *cardsController = [OADestinationCardsViewController sharedInstance];
    if (cardsController.view.superview)
    {
        CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height;
        CGFloat h = DeviceScreenHeight - y;
    
        [cardsController doViewWillDisappear];
        
        if (!_destinationViewController.navBarHidden)
        {
            _destinationViewController.navBarHidden = YES;
            [_destinationViewController updateFrame:YES];
        }
        else
        {
            [self.destinationViewController updateCloseButton];
        }
        
        if (animated)
        {
            [UIView animateWithDuration:.25 animations:^{
                cardsController.view.frame = CGRectMake(0.0, y - h, DeviceScreenWidth, h);
                _shadeView.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                
                [self removeShade];
                
                [cardsController.view removeFromSuperview];
                [cardsController removeFromParentViewController];
            }];
        }
        else
        {
            [self removeShade];
            [cardsController.view removeFromSuperview];
            [cardsController removeFromParentViewController];
        }
    }
}

- (void)openHideDestinationCardsView
{
    if (![OADestinationCardsViewController sharedInstance].view.superview)
        [self openDestinationCardsView];
    else
        [self hideDestinationCardsView];
}

-(void)destinationViewLayoutDidChange:(BOOL)animated
{
    if ([_hudViewController isKindOfClass:[OABrowseMapAppModeHudViewController class]]) {
        OABrowseMapAppModeHudViewController *browserMap = (OABrowseMapAppModeHudViewController *)_hudViewController;
        [browserMap updateDestinationViewLayout:animated];
        
    } else if ([_hudViewController isKindOfClass:[OADriveAppModeHudViewController class]]) {
        OADriveAppModeHudViewController *drive = (OADriveAppModeHudViewController *)_hudViewController;
        [drive updateDestinationViewLayout:animated];
    }
    
    OADestinationCardsViewController *cardsController = [OADestinationCardsViewController sharedInstance];
    if (cardsController.view.superview && !cardsController.isHiding && [OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        [UIView animateWithDuration:(animated ? .25 : 0.0) animations:^{
            cardsController.view.frame = CGRectMake(0.0, _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height, DeviceScreenWidth, DeviceScreenHeight - _destinationViewController.view.frame.origin.y - _destinationViewController.view.frame.size.height);
        }];
    }
}

- (void)destinationViewMoveTo:(OADestination *)destination
{
    if (destination.routePoint &&
        [_mapViewController findWpt:CLLocationCoordinate2DMake(destination.latitude, destination.longitude)])
    {
        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
        item.point = _mapViewController.foundWpt;
        [self openTargetViewWithWpt:item pushed:NO showFullMenu:NO];
        return;
    }

    [_mapViewController showContextPinMarker:destination.latitude longitude:destination.longitude animated:YES];

    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    CGPoint touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenWidth / 2.0);
    touchPoint.x *= renderView.contentScaleFactor;
    touchPoint.y *= renderView.contentScaleFactor;

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = destination.desc;
    UIImage *icon = [UIImage imageNamed:destination.markerResourceName];
    
    if (destination.parking)
        targetPoint.type = OATargetParking;
    else
        targetPoint.type = OATargetDestination;
    
    targetPoint.targetObj = destination;
    
    _targetDestination = destination;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    _targetMode = EOATargetPoint;
    _targetLatitude = destination.latitude;
    _targetLongitude = destination.longitude;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(destination.latitude, destination.longitude);
    targetPoint.title = _formattedTargetName;
    targetPoint.zoom = renderView.zoom;
    targetPoint.touchPoint = touchPoint;
    targetPoint.icon = icon;
    targetPoint.titleAddress = [self findRoadNameByLat:destination.latitude lon:destination.longitude];
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
        [self targetGoToPoint];
    }];
}

@end
