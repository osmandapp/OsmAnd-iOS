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
    
    OAAppSettings *_settings;
    
    UILongPressGestureRecognizer *_quickActionsButtonDragRecognizer;
    UILongPressGestureRecognizer *_map3dModeButtonDragRecognizer;
    OAQuickActionsSheetView *_actionsView;
    BOOL _isActionsViewVisible;
    
    CGFloat _cachedYViewPort;
    OAAutoObserverProxy *_map3dModeObserver;
    OAAutoObserverProxy *_applicationModeObserver;
}

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController
{
    self = [super initWithNibName:@"OAFloatingButtonsHudViewController"
                           bundle:nil];
    if (self)
    {
        _mapHudController = mapHudController;
        _settings = [OAAppSettings sharedManager];
        _isActionsViewVisible = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _quickActionFloatingButton.alpha = [_settings.quickActionIsOn get] ? 1 : 0;
    _quickActionFloatingButton.userInteractionEnabled = [_settings.quickActionIsOn get];
    _quickActionFloatingButton.tintColorDay = UIColorFromRGB(color_primary_purple);
    _quickActionFloatingButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
    [_quickActionFloatingButton updateColorsForPressedState:NO];
    [self restoreQuickActionButtonPosition];
    
    _quickActionsButtonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onQuickActionButtonDragged:)];
    [_quickActionsButtonDragRecognizer setMinimumPressDuration:0.5];
    [_quickActionFloatingButton addGestureRecognizer:_quickActionsButtonDragRecognizer];
    _quickActionFloatingButton.accessibilityLabel = OALocalizedString(@"configure_screen_quick_action");
    
    _map3dModeFloatingButton.alpha = 0;
    
    [self onMap3dModeUpdated];
    [self restoreQuickActionButtonPosition];
    
    _map3dModeButtonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onMap3dModeButtonDragged:)];
    [_map3dModeButtonDragRecognizer setMinimumPressDuration:0.5];
    [_map3dModeFloatingButton addGestureRecognizer:_map3dModeButtonDragRecognizer];
    
    _map3dModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                   withHandler:@selector(onMap3dModeUpdated)
                                                    andObserve:[OARootViewController instance].mapPanel.mapViewController.elevationAngleObservable];
    _applicationModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onApplicationModeChanged)
                                                          andObserve:[OsmAndApp instance].data.applicationModeChangedObservable];

    [self updateColors:NO];
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

- (void) updateColors:(BOOL)isNight
{
    [_quickActionFloatingButton updateColorsForPressedState:NO];
    if (_isActionsViewVisible)
        [_quickActionFloatingButton setImage:[UIImage templateImageNamed:@"ic_action_close_banner"] forState:UIControlStateNormal];
    else
        [_quickActionFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_quick_action"] forState:UIControlStateNormal];
    
    [self onMap3dModeUpdated];
}

- (void) onMap3dModeUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupMap3dModeButtonVisibility];
        [_map3dModeFloatingButton updateColorsForPressedState: NO];
        if ([OAMapViewTrackingUtilities.instance isIn3dMode])
        {
            [_map3dModeFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_2d"] forState:UIControlStateNormal];
            _map3dModeFloatingButton.accessibilityLabel = OALocalizedString(@"map_3d_mode_action");
        }
        else
        {
            [_map3dModeFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_3d"] forState:UIControlStateNormal];
            _map3dModeFloatingButton.accessibilityLabel = OALocalizedString(@"map_2d_mode_action");
        }
        EOAMap3DModeVisibility visibilityMode = ((EOAMap3DModeVisibility) [_settings.map3dMode get]);
        _map3dModeFloatingButton.accessibilityValue = [OAMap3DModeVisibility getTitle:visibilityMode];
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
    BOOL hideQuickButton = ![_settings.quickActionIsOn get] ||
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

    BOOL hideButton = [_settings.map3dMode get] == EOAMap3DModeVisibilityHidden ||
    ([_settings.map3dMode get] == EOAMap3DModeVisibilityVisibleIn3DMode &&
        ![OAMapViewTrackingUtilities.instance isIn3dMode])  ||
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

- (void) restoreQuickActionButtonPosition
{
    CGFloat x;
    CGFloat y;
    CGFloat defaultX;
    CGFloat defaultY;
    CGFloat btnWidth = kHudQuickActionButtonHeight;
    BOOL isLandscape = [OAUtilities isLandscape];
    if (isLandscape)
    {
        defaultX = [self getRightMargin] - 2 * btnWidth - 2 * kHudButtonsOffset - [self getHalfSmallButtonWidth];
        defaultY = [self getBottomMargin] - [self getHalfSmallButtonWidth];
        x = [_settings.quickActionLandscapeX get];
        y = [_settings.quickActionLandscapeY get];
        [self setPositionForButton:_quickActionFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
    else
    {
        defaultX = [self getRightMargin] - [self getHalfSmallButtonWidth];
        defaultY = [self getBottomMargin] - 2 * btnWidth - 2 * kHudButtonsOffset - [self getHalfSmallButtonWidth];
        x = [_settings.quickActionPortraitX get];
        y = [_settings.quickActionPortraitY get];
        [self setPositionForButton:_quickActionFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
}

- (void) restoreMap3dModeButtonPosition
{
    CGFloat x;
    CGFloat y;
    CGFloat defaultX;
    CGFloat defaultY;
    CGFloat btnWidth = kHudQuickActionButtonHeight;
    BOOL isLandscape = [OAUtilities isLandscape];
    if (isLandscape)
    {
        defaultX = [self getRightMargin] - btnWidth - kHudButtonsOffset - [self getHalfSmallButtonWidth];
        defaultY = [self getBottomMargin] - btnWidth - kHudButtonsOffset - [self getHalfSmallButtonWidth];
        x = [_settings.map3dModeLandscapeX get];
        y = [_settings.map3dModeLandscapeY get];
        [self setPositionForButton:_map3dModeFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
    else
    {
        defaultX = [self getRightMargin] - btnWidth - kHudButtonsOffset - [self getHalfSmallButtonWidth];
        defaultY = [self getBottomMargin] - btnWidth - kHudButtonsOffset - [self getHalfSmallButtonWidth];
        x = [_settings.map3dModePortraitX get];
        y = [_settings.map3dModePortraitY get];
        [self setPositionForButton:_map3dModeFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
}

- (void) setPositionForButton:(UIButton*)button x:(CGFloat)x y:(CGFloat)y defaultX:(CGFloat)defaultX defaultY:(CGFloat)defaultY
{
    if (x <= 0)
        x = defaultX;
    else if (x > [self getRightMargin])
        x = [self getRightMargin];

    if (y <= 0)
        y = defaultY;
    else if (y > [self getBottomMargin])
        y = [self getBottomMargin];
    
    button.frame = CGRectMake(x, y, button.frame.size.width, button.frame.size.height);
}

- (void)restoreControlsPosition 
{
    [self restoreQuickActionButtonPosition];
    [self restoreMap3dModeButtonPosition];
    [self restorePinPosition];
}

- (void)viewWillLayoutSubviews
{
    [self restoreControlsPosition];
    if (_actionsView.superview)
        [self adjustMapViewPort];
}

- (void)moveToPoint:(CGPoint)newPosition button:(UIButton *)button
{
    CGFloat halfBigButtonWidth = button.frame.size.width / 2;
    
    CGFloat x = newPosition.x;
    CGFloat y = newPosition.y;
    
    if (x <= [self getLeftMargin])
        x = [self getLeftMargin];
    else if (x >= [self getRightMargin])
        x = [self getRightMargin];
    
    if (y <= [self getTopMargin])
        y = [self getTopMargin];
    else if (y >= [self getBottomMargin])
        y = [self getBottomMargin];
    
    button.frame = CGRectMake(x - halfBigButtonWidth, y - halfBigButtonWidth, button.frame.size.width, button.frame.size.height);
}

- (CGFloat) getHalfSmallButtonWidth
{
    return kHudQuickActionButtonHeight / 2;
}

- (CGFloat) getLeftMargin
{
    return OAUtilities.getLeftMargin + kHudButtonsOffset + [self getHalfSmallButtonWidth];
}

- (CGFloat) getRightMargin
{
    CGFloat halfSmallButtonWidth = kHudQuickActionButtonHeight / 2;
    return DeviceScreenWidth - OAUtilities.getLeftMargin - kHudButtonsOffset - [self getHalfSmallButtonWidth];
}

- (CGFloat) getTopMargin
{
    return OAUtilities.getStatusBarHeight + kHudButtonsOffset + [self getHalfSmallButtonWidth];
}

- (CGFloat) getBottomMargin
{
    return DeviceScreenHeight - OAUtilities.getBottomMargin - kHudButtonsOffset - [self getHalfSmallButtonWidth];
}

- (void) onQuickActionButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        _quickActionFloatingButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        [self moveToPoint:[recognizer locationInView:self.view] button:_quickActionFloatingButton];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self moveToPoint:[recognizer locationInView:self.view] button:_quickActionFloatingButton];
        _quickActionFloatingButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        CGPoint pos = _quickActionFloatingButton.frame.origin;
        if ([OAUtilities isLandscape])
            [_settings setQuickActionCoordinatesLandscape:pos.x y:pos.y];
        else
            [_settings setQuickActionCoordinatesPortrait:pos.x y:pos.y];
    }
}

- (void) onMap3dModeButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        _map3dModeFloatingButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        [self moveToPoint:[recognizer locationInView:self.view] button:_map3dModeFloatingButton];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self moveToPoint:[recognizer locationInView:self.view] button:_map3dModeFloatingButton];
        _map3dModeFloatingButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        CGPoint pos = _map3dModeFloatingButton.frame.origin;
        if ([OAUtilities isLandscape])
        {
            [_settings.map3dModeLandscapeX set:pos.x];
            [_settings.map3dModeLandscapeY set:pos.y];
        }
        else
            [_settings.map3dModePortraitX set:pos.x];
            [_settings.map3dModePortraitY set:pos.y];
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
    [self updateColors:NO];
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
    [self updateColors:NO];
}

- (IBAction)quickActionButtonPressed:(id)sender
{
    if (!_actionsView)
    {
        _actionsView = [[OAQuickActionsSheetView alloc] init];
        _actionsView.delegate = self;
    }
    if (_actionsView.superview)
        [self hideActionsSheetAnimated];
    else
        [self showActionsSheetAnimated];
}

- (IBAction)map3dModeButtonPressed:(id)sender
{
    _map3dModeFloatingButton.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kFastAnimationTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _map3dModeFloatingButton.enabled = YES;
    });
    [OAMapViewTrackingUtilities.instance switchMap3dMode];
    [self updateColors:NO];
}

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated];
}

@end
