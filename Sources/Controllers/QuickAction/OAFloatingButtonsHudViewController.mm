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

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f
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
    
    _quickActionsButtonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onQuickActionButtonDragged:)];
    [_quickActionsButtonDragRecognizer setMinimumPressDuration:0.5];
    [_quickActionFloatingButton addGestureRecognizer:_quickActionsButtonDragRecognizer];
    _quickActionFloatingButton.accessibilityLabel = OALocalizedString(@"configure_screen_quick_action");
    [self setQuickActionButtonMargin];
    
    _map3dModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                   withHandler:@selector(onMap3dModeUpdated)
                                                    andObserve:[OsmAndApp instance].map3dModeObservable];
    
    [self updateColors:NO];
}

- (void) setPinPosition
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
            [_map3dModeFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_3d"] forState:UIControlStateNormal];
            _map3dModeFloatingButton.accessibilityLabel = OALocalizedString(@"map_3d_mode_action");
        }
        else
        {
            [_map3dModeFloatingButton setImage:[UIImage templateImageNamed:@"ic_custom_2d"] forState:UIControlStateNormal];
            _map3dModeFloatingButton.accessibilityLabel = OALocalizedString(@"map_2d_mode_action");
        }
        EOAMap3DModeVisibility visibilityMode = ((EOAMap3DModeVisibility) [_settings.map3dMode get]);
        _map3dModeFloatingButton.accessibilityValue = [OAMap3DModeVisibility getTitle:visibilityMode];
    });
}

- (void)adjustMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if ([OAUtilities isLandscape])
    {
        mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
        mapView.viewportYScale = VIEWPORT_NON_SHIFTED_SCALE;
    }
    else
    {
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
        mapView.viewportYScale = (DeviceScreenHeight - _actionsView.frame.size.height) / DeviceScreenHeight;
    }
}

- (void) restoreMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != _cachedYViewPort)
        mapView.viewportYScale = _cachedYViewPort;
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

// Android counterpart: setQuickActionButtonMargin()
- (void) setQuickActionButtonMargin
{
    CGFloat screenHeight = DeviceScreenHeight;
    CGFloat screenWidth = DeviceScreenWidth;
    CGFloat btnHeight = kHudQuickActionButtonHeight;
    CGFloat btnWidth = kHudQuickActionButtonHeight;
    CGFloat maxRightMargin = screenWidth - btnWidth - 2 * OAUtilities.getLeftMargin;
    CGFloat maxBottomMargin = screenHeight - btnHeight - OAUtilities.getBottomMargin;
    
    CGFloat x;
    CGFloat y;
    CGFloat defaultX;
    CGFloat defaultY;
    BOOL isLandscape = [OAUtilities isLandscape];
    if (isLandscape)
    {
        defaultX = maxRightMargin - 2 * btnWidth - 2 * kHudButtonsOffset;
        defaultY = maxBottomMargin;
        x = [_settings.quickActionLandscapeX get];
        y = [_settings.quickActionLandscapeY get];
        [self setPositionForButton:_quickActionFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
    else
    {
        defaultX = maxRightMargin - kHudButtonsOffset;
        defaultY = maxBottomMargin - 2 * btnWidth - 2 * kHudButtonsOffset;
        x = [_settings.quickActionPortraitX get];
        y = [_settings.quickActionPortraitY get];
        [self setPositionForButton:_quickActionFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
}

- (void) setMap3dModeButtonMargin
{
    CGFloat screenHeight = DeviceScreenHeight;
    CGFloat screenWidth = DeviceScreenWidth;
    CGFloat btnHeight = kHudQuickActionButtonHeight;
    CGFloat btnWidth = kHudQuickActionButtonHeight;
    CGFloat maxRightMargin = screenWidth - btnWidth - 2 * OAUtilities.getLeftMargin;
    CGFloat maxBottomMargin = screenHeight - btnHeight - OAUtilities.getBottomMargin;
    
    CGFloat x;
    CGFloat y;
    CGFloat defaultX;
    CGFloat defaultY;
    BOOL isLandscape = [OAUtilities isLandscape];
    if (isLandscape)
    {
        defaultX = maxRightMargin - btnWidth - kHudButtonsOffset;
        defaultY = maxBottomMargin - btnWidth - kHudButtonsOffset;
        x = [_settings.map3dModeLandscapeX get];
        y = [_settings.map3dModeLandscapeY get];
        [self setPositionForButton:_map3dModeFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
    else
    {
        defaultX = maxRightMargin - btnWidth - 2 * kHudButtonsOffset;
        defaultY = maxBottomMargin - btnWidth - kHudButtonsOffset;
        x = [_settings.map3dModePortraitX get];
        y = [_settings.map3dModePortraitY get];
        [self setPositionForButton:_map3dModeFloatingButton x:x y:y defaultX:defaultX defaultY:defaultY];
    }
}

- (void) setPositionForButton:(UIButton*)button x:(CGFloat)x y:(CGFloat)y defaultX:(CGFloat)defaultX defaultY:(CGFloat)defaultY
{
    CGFloat screenHeight = DeviceScreenHeight;
    CGFloat screenWidth = DeviceScreenWidth;
    CGFloat btnHeight = button.frame.size.height;
    CGFloat btnWidth = button.frame.size.width;
    CGFloat maxRightMargin = screenWidth - btnWidth - 2 * OAUtilities.getLeftMargin;
    CGFloat maxBottomMargin = screenHeight - btnHeight - OAUtilities.getBottomMargin;
    
    // check limits
    if (x <= 0)
        x = defaultX;
    else if (x > maxRightMargin)
        x = maxRightMargin;

    if (y <= OAUtilities.getTopMargin)
        y = defaultY;
    else if (y > maxBottomMargin)
        y = maxBottomMargin;
    
    button.frame = CGRectMake(x, y, btnWidth, btnHeight);
}

- (void)viewWillLayoutSubviews
{
    [self setQuickActionButtonMargin];
    [self setMap3dModeButtonMargin];
    [self setPinPosition];
    if (_actionsView.superview)
        [self adjustMapViewPort];
}

- (void)moveToPoint:(CGPoint)newPosition button:(UIButton *)button
{
    CGSize bigButtonSize = button.frame.size;
    CGFloat halfBigButtonWidth = bigButtonSize.width / 2;
    CGFloat halfSmallButtonWidth = kHudQuickActionButtonHeight / 2;
    CGFloat leftSafeMargin = halfSmallButtonWidth + 1;
    CGFloat rightSafeMargin = DeviceScreenWidth - 2 * OAUtilities.getLeftMargin - halfSmallButtonWidth;
    CGFloat topSafeMargin = OAUtilities.getStatusBarHeight + halfSmallButtonWidth + 1;
    CGFloat bottomSafeMargin = DeviceScreenHeight - OAUtilities.getBottomMargin - halfSmallButtonWidth;
    
    CGFloat x = newPosition.x;
    CGFloat y = newPosition.y;
    
    if (x <= leftSafeMargin)
        x = leftSafeMargin;
    else if (x >= rightSafeMargin)
        x = rightSafeMargin;
    
    if (y <= topSafeMargin)
        y = topSafeMargin;
    else if (y >= bottomSafeMargin)
        y = bottomSafeMargin;
    
    button.frame = CGRectMake(x - halfBigButtonWidth, y - halfBigButtonWidth, button.frame.size.width, button.frame.size.height);
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
        [[UIApplication sharedApplication].keyWindow addSubview:_actionsView];
        [_actionsView layoutSubviews];
        _cachedYViewPort = [OARootViewController instance].mapPanel.mapViewController.mapView.viewportYScale;
        [self adjustMapViewPort];
    }];
    [self setPinPosition];
    _isActionsViewVisible = YES;
    [_mapHudController hideTopControls];
    [_mapHudController showBottomControls:0. animated:YES];
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
        [_mapHudController showTopControls:NO];
        [_mapHudController showBottomControls:0. animated:YES];
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
    [OAMapViewTrackingUtilities.instance onMap3dModeChanged];
    [self updateColors:NO];
}

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated];
}

@end
