//
//  OAFloatingButtonsHudViewController.m
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAFloatingButtonsHudViewController.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapInfoController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAQuickActionsSheetView.h"
#import "OAColors.h"
#import "OAHudButton.h"
#import "Localization.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAAutoObserverProxy.h"
#import "OAMap3DModeVisibilityType.h"

#import <AudioToolbox/AudioServices.h>
#import "OsmAnd_Maps-Swift.h"

#define kHudButtonsOffset 16.0f
#define kHudQuickActionButtonHeight 50.0f

@interface OAFloatingButtonsHudViewController () <OAQuickActionsSheetDelegate>

@property (weak, nonatomic) IBOutlet OAHudButton *map3dModeFloatingButton;
@property (weak, nonatomic) IBOutlet OAHudButton *quickActionFloatingButton;
@property (weak, nonatomic) IBOutlet UIImageView *quickActionPin;

@end

@implementation OAFloatingButtonsHudViewController
{
    OAMapHudViewController *_mapHudController;
    
    OAMapButtonsHelper *_mapButtonsHelper;
    OAQuickActionButtonState *_quickActionButtonState;
    OAMap3DButtonState *_map3DButtonState;
    
    UILongPressGestureRecognizer *_quickActionsButtonDragRecognizer;
    UILongPressGestureRecognizer *_map3dModeButtonDragRecognizer;
    OAQuickActionsSheetView *_actionsView;
    BOOL _isActionsViewVisible;
    
    CGFloat _cachedYViewPort;
    OAAutoObserverProxy *_map3dModeObserver;
    OAAutoObserverProxy *_applicationModeObserver;
    OAAutoObserverProxy *_actionsChangedObserver;
}

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController
{
    self = [super initWithNibName:@"OAFloatingButtonsHudViewController"
                           bundle:nil];
    if (self)
    {
        _mapHudController = mapHudController;
        _mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
        _quickActionButtonState = [_mapButtonsHelper getButtonStateById:OAQuickActionButtonState.defaultButtonId];
        _map3DButtonState = [_mapButtonsHelper getMap3DButtonState];
        _isActionsViewVisible = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_quickActionFloatingButton setTag:[OAUtilities getQuickActionButtonTag]];
    _quickActionFloatingButton.alpha = [_quickActionButtonState isEnabled] ? 1 : 0;
    _quickActionFloatingButton.userInteractionEnabled = [_quickActionButtonState isEnabled];
    _quickActionFloatingButton.tintColorDay = UIColorFromRGB(color_primary_purple);
    _quickActionFloatingButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
    [_quickActionFloatingButton updateColorsForPressedState:NO];

    [_map3DButtonState.fabMarginPref restorePosition:_map3dModeFloatingButton];
    
    _quickActionsButtonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onQuickActionButtonDragged:)];
    [_quickActionsButtonDragRecognizer setMinimumPressDuration:0.5];
    [_quickActionFloatingButton addGestureRecognizer:_quickActionsButtonDragRecognizer];
    _quickActionFloatingButton.accessibilityLabel = OALocalizedString(@"configure_screen_quick_action");
    
    [_map3dModeFloatingButton setTag:[OAUtilities getMap3DModeButtonTag]];
    _map3dModeFloatingButton.alpha = 0;

    [self onMap3dModeUpdated];
    [_quickActionButtonState.fabMarginPref restorePosition:_quickActionFloatingButton];
    
    _map3dModeButtonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onMap3dModeButtonDragged:)];
    [_map3dModeButtonDragRecognizer setMinimumPressDuration:0.5];
    [_map3dModeFloatingButton addGestureRecognizer:_map3dModeButtonDragRecognizer];
    
    _map3dModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                   withHandler:@selector(onMap3dModeUpdated)
                                                    andObserve:[OARootViewController instance].mapPanel.mapViewController.elevationAngleObservable];
    _applicationModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onApplicationModeChanged)
                                                          andObserve:[OsmAndApp instance].data.applicationModeChangedObservable];
    _actionsChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(updateColors)
                                                         andObserve:[OAMapButtonsHelper sharedInstance].quickActionListChangedObservable];
    [self updateColors];
}

- (void)dealloc
{
    if (_applicationModeObserver)
    {
        [_applicationModeObserver detach];
        _applicationModeObserver = nil;
    }
    if (_map3dModeObserver)
    {
        [_map3dModeObserver detach];
        _map3dModeObserver = nil;
    }
}

- (void) restorePinPosition
{
    BOOL isLandscape = OAUtilities.isLandscape;
    CGRect pinFrame = _quickActionPin.frame;
    CGFloat width = isLandscape ? DeviceScreenWidth * 1.5 : DeviceScreenWidth;
    CGFloat originX = width / 2 - pinFrame.size.width / 2;
    CGFloat originY = isLandscape ? (DeviceScreenHeight / 2 - pinFrame.size.height) : (DeviceScreenHeight * (1.0 - (_actionsView.frame.size.height / DeviceScreenHeight)) / 2 - pinFrame.size.height);
    if (!isnan(originX) && !isnan(originY))
    {
        pinFrame.origin = CGPointMake(originX, originY);
        _quickActionPin.frame = pinFrame;
    }
}

- (void)updateColors
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_quickActionFloatingButton updateColorsForPressedState:NO];
        if (_quickActionButtonState.quickActions.count == 1)
        {
            [_quickActionFloatingButton setImage:[_quickActionButtonState getIcon] forState:UIControlStateNormal];
        }
        else
        {
            if (_isActionsViewVisible)
                [_quickActionFloatingButton setImage:[UIImage templateImageNamed:@"ic_action_close_banner"] forState:UIControlStateNormal];
            else
                [_quickActionFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_quick_action"] forState:UIControlStateNormal];
        }
    });
    [self onMap3dModeUpdated];
}

- (void) onMap3dModeUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupMap3dModeButtonVisibility];
        [_map3dModeFloatingButton updateColorsForPressedState: NO];
        if ([OAMapViewTrackingUtilities.instance is3DMode])
        {
            [_map3dModeFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_2d"] forState:UIControlStateNormal];
            _map3dModeFloatingButton.accessibilityLabel = OALocalizedString(@"map_3d_mode_action");
        }
        else
        {
            [_map3dModeFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_3d"] forState:UIControlStateNormal];
            _map3dModeFloatingButton.accessibilityLabel = OALocalizedString(@"map_2d_mode_action");
        }
        EOAMap3DModeVisibility map3DMode = [[[OAMapButtonsHelper sharedInstance] getMap3DButtonState] getVisibility];
        _map3dModeFloatingButton.accessibilityValue = [EOAMap3DModeVisibilityWrapper getTitleForType:map3DMode];
    });
}

- (void)onApplicationModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateViewVisibility];
        [self restoreControlsPosition];
    });
}

- (void)adjustMapViewPort
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL isLandscape = [OAUtilities isLandscape];
    [mapPanel.mapViewController setViewportScaleX:isLandscape ? kViewportBottomScale : kViewportScale
                                                y:isLandscape ? kViewportScale : (DeviceScreenHeight - _actionsView.frame.size.height) / DeviceScreenHeight];
}

- (void) restoreMapViewPort
{
    [[OARootViewController instance].mapPanel.mapViewController setViewportScaleX:kViewportScale y:_cachedYViewPort];
}

- (void) updateViewVisibility
{
//    setLayerState(false);
//    isLayerOn = quickActionRegistry.isQuickActionOn();
    [self setupQuickActionBtnVisibility];
    [self setupMap3dModeButtonVisibility];
}

- (void) setupQuickActionBtnVisibility
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    //    contextMenuLayer.isInChangeMarkerPositionMode() ||
    //    measurementToolLayer.isInMeasurementMode() ||
    BOOL hideQuickButton = ![_quickActionButtonState isEnabled] ||
    [mapPanel isContextMenuVisible] ||
    [mapPanel gpxModeActive] ||
    [mapPanel isRouteInfoVisible] ||
    mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
    
    [UIView animateWithDuration:.25 animations:^{
        _quickActionFloatingButton.alpha = hideQuickButton ? 0 : 1;
    } completion:^(BOOL finished) {
        _quickActionFloatingButton.userInteractionEnabled = !hideQuickButton;
    }];
}

- (void) setupMap3dModeButtonVisibility
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;

    EOAMap3DModeVisibility map3DMode = [_map3DButtonState getVisibility];
    BOOL hideButton = map3DMode == EOAMap3DModeVisibilityHidden ||
    (map3DMode == EOAMap3DModeVisibilityVisibleIn3DMode &&
        ![OAMapViewTrackingUtilities.instance is3DMode])  ||
    [mapPanel isContextMenuVisible] ||
    [mapPanel gpxModeActive] ||
    [mapPanel isRouteInfoVisible] ||
    mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
    
    [UIView animateWithDuration:.25 animations:^{
        _map3dModeFloatingButton.alpha = hideButton ? 0 : 1;
    } completion:^(BOOL finished) {
        _map3dModeFloatingButton.userInteractionEnabled = !hideButton;
    }];
}

- (BOOL) isQuickActionFloatingButtonVisible
{
    return _quickActionFloatingButton.alpha == 1;
}

- (void)restoreControlsPosition 
{
    [_quickActionButtonState.fabMarginPref restorePosition:_quickActionFloatingButton];
    [_map3DButtonState.fabMarginPref restorePosition:_map3dModeFloatingButton];
    [self restorePinPosition];
}

- (void)viewWillLayoutSubviews
{
    [self restoreControlsPosition];
    if (_actionsView.superview)
        [self adjustMapViewPort];
}

- (void)onQuickActionButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    [self onButtonDragged:recognizer
                   button:_quickActionFloatingButton
      fabMarginPreference:_quickActionButtonState.fabMarginPref];
}

- (void)onMap3dModeButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    [self onButtonDragged:recognizer
                   button:_map3dModeFloatingButton
      fabMarginPreference:_map3DButtonState.fabMarginPref];
}

- (void)onButtonDragged:(UILongPressGestureRecognizer *)recognizer
                 button:(OAHudButton *)button
    fabMarginPreference:(OAFabMarginPreference *)fabMarginPreference
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        button.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }
    else
    {
        [fabMarginPreference moveToPoint:[recognizer locationInView:self.view]
                                  button:button];
        if (recognizer.state == UIGestureRecognizerStateEnded)
        {
            button.transform = CGAffineTransformMakeScale(1.0, 1.0);
            CGPoint pos = button.frame.origin;
            if ([OAUtilities isLandscape])
                [fabMarginPreference setLandscapeFabMarginWithX:pos.x y:pos.y];
            else
                [fabMarginPreference setPortraitFabMarginWithX:pos.x y:pos.y];
        }
    }
}

- (BOOL)isActionSheetVisible
{
    return _isActionsViewVisible;
}

- (void)showActionsSheetAnimated
{
    [_mapHudController hideWeatherToolbarIfNeeded];

    _actionsView.frame = CGRectMake(OAUtilities.getLeftMargin, DeviceScreenHeight, _actionsView.frame.size.width, _actionsView.frame.size.height);
    [UIView animateWithDuration:.3 animations:^{
        _quickActionPin.hidden = NO;
        [[UIApplication sharedApplication].mainWindow addSubview:_actionsView];
        [_actionsView layoutSubviews];
        _cachedYViewPort = [OARootViewController instance].mapPanel.mapViewController.mapView.viewportYScale;
        [self adjustMapViewPort];
    }];
    [self restorePinPosition];
    _isActionsViewVisible = YES;
    [_mapHudController updateControlsLayout:YES];
    [self updateColors];
}

- (void)hideActionsSheetAnimated
{
    if (_actionsView.hidden || !_actionsView.superview)
        return;

    _isActionsViewVisible = NO;
    [UIView animateWithDuration:.3 animations:^{
        _quickActionPin.hidden = YES;
        _actionsView.frame = CGRectMake(OAUtilities.getLeftMargin, DeviceScreenHeight, _actionsView.bounds.size.width, _actionsView.bounds.size.height);
        [self restoreMapViewPort];
    } completion:^(BOOL finished) {
        [_actionsView removeFromSuperview];
        [_mapHudController updateControlsLayout:YES];
    }];
    [self updateColors];
}

- (IBAction)quickActionButtonPressed:(id)sender
{
    if (_quickActionButtonState.quickActions.count == 1)
    {
        [_quickActionButtonState.quickActions.firstObject execute];
    }
    else
    {
        if (!_actionsView)
        {
            _actionsView = [[OAQuickActionsSheetView alloc] initWithButtonState:_quickActionButtonState];
            _actionsView.delegate = self;
        }
        if (_actionsView.superview)
            [self hideActionsSheetAnimated];
        else
            [self showActionsSheetAnimated];
    }
}

- (IBAction)map3dModeButtonPressed:(id)sender
{
    [OAMapViewTrackingUtilities.instance switchMap3dMode];
    [self updateColors];
}

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated];
}

@end
