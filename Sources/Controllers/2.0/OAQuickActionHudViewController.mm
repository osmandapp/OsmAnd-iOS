//
//  OAQuickActionHudViewController.m
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAQuickActionsSheetView.h"
#import "OAColors.h"

#import <AudioToolbox/AudioServices.h>

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@interface OAQuickActionHudViewController () <OAQuickActionsSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *quickActionFloatingButton;
@property (weak, nonatomic) IBOutlet UIImageView *quickActionPin;

@end

@implementation OAQuickActionHudViewController
{
    OAMapHudViewController *_mapHudController;
    
    OAAppSettings *_settings;
    
    UILongPressGestureRecognizer *_buttonDragRecognizer;
    OAQuickActionsSheetView *_actionsView;
    
    CGFloat _cachedYViewPort;
}

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController
{
    self = [super initWithNibName:@"OAQuickActionHudViewController"
                           bundle:nil];
    if (self)
    {
        _mapHudController = mapHudController;
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_quickActionFloatingButton setImage:[[UIImage imageNamed:@"ic_custom_quick_action"]
                                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                forState:UIControlStateNormal];
    _quickActionFloatingButton.hidden = ![_settings.quickActionIsOn get];
    _buttonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonDragged:)];
    [_buttonDragRecognizer setMinimumPressDuration:0.5];
    [_quickActionFloatingButton addGestureRecognizer:_buttonDragRecognizer];
    
    [self setQuickActionButtonPosition];
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
    [_quickActionFloatingButton setBackgroundImage:[UIImage imageNamed:isNight ? @"bg_circle_button_night" : @"bg_circle_button_day"] forState:UIControlStateNormal];
    [_quickActionFloatingButton setTintColor:isNight ? UIColor.whiteColor : UIColorFromRGB(color_primary_purple)];
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
        mapView.viewportYScale = _actionsView.frame.size.height / DeviceScreenHeight;
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
}

- (void) setupQuickActionBtnVisibility
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    //    contextMenuLayer.isInChangeMarkerPositionMode() ||
    //    measurementToolLayer.isInMeasurementMode() ||
    BOOL hideQuickButton = ![_settings.quickActionIsOn get] ||
    [mapPanel isContextMenuVisible] ||
    [mapPanel gpxModeActive] ||
    [mapPanel isRouteInfoVisible];
    _quickActionFloatingButton.hidden = hideQuickButton;
}


// Android counterpart: setQuickActionButtonMargin()
- (void) setQuickActionButtonPosition
{
    CGFloat x, y;
    CGFloat w = _quickActionFloatingButton.frame.size.width;
    CGFloat h = _quickActionFloatingButton.frame.size.height;
    BOOL isLandscape = [OAUtilities isLandscape];
    if (isLandscape)
    {
        x = [_settings.quickActionLandscapeX get];
        y = [_settings.quickActionLandscapeY get];
    }
    else
    {
        x = [_settings.quickActionPortraitX get];
        y = [_settings.quickActionPortraitY get];
    }
    if (x == 0. && y == 0.)
    {
        if (isLandscape)
        {
            x = _mapHudController.mapModeButton.frame.origin.x - w;
            y = _mapHudController.mapModeButton.frame.origin.y;
        }
        else
        {
            x = _mapHudController.zoomButtonsView.frame.origin.x;
            y = _mapHudController.zoomButtonsView.frame.origin.y - h;
        }
    }
    _quickActionFloatingButton.frame = CGRectMake(x, y, w, h);
}

- (void)viewWillLayoutSubviews
{
    [self setQuickActionButtonPosition];
    [self setPinPosition];
    if (_actionsView.superview)
        [self adjustMapViewPort];
}

- (void)moveToPoint:(CGPoint)newPosition
{
    CGPoint safePosition = newPosition;
    CGSize buttonSize = _quickActionFloatingButton.frame.size;
    CGFloat halfButtonWidth = buttonSize.width / 2;
    CGFloat halfButtonHeight = buttonSize.height / 2;
    
    CGFloat statusBarHeight = OAUtilities.getStatusBarHeight;
    CGFloat bottomSafe = DeviceScreenHeight - OAUtilities.getBottomMargin;
    CGFloat rightSafe = DeviceScreenWidth - OAUtilities.getLeftMargin * 2;
    
    if (newPosition.x < halfButtonWidth)
        safePosition.x = halfButtonWidth;
    else if (newPosition.x > rightSafe - halfButtonWidth)
        safePosition.x = rightSafe - halfButtonWidth;

    if (newPosition.y < statusBarHeight + halfButtonHeight)
        safePosition.y = statusBarHeight + halfButtonHeight;
    else if (newPosition.y > bottomSafe - halfButtonHeight)
        safePosition.y = bottomSafe - halfButtonHeight;

    _quickActionFloatingButton.frame = CGRectMake(safePosition.x - halfButtonWidth, safePosition.y - halfButtonHeight, _quickActionFloatingButton.frame.size.width, _quickActionFloatingButton.frame.size.height);
}

- (void) onButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        _quickActionFloatingButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        [self moveToPoint:[recognizer locationInView:self.view]];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self moveToPoint:[recognizer locationInView:self.view]];
        _quickActionFloatingButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        CGPoint pos = _quickActionFloatingButton.frame.origin;
        if ([OAUtilities isLandscape])
            [_settings setQuickActionCoordinatesLandscape:pos.x y:pos.y];
        else
            [_settings setQuickActionCoordinatesPortrait:pos.x y:pos.y];
    }
}

- (void)hideActionsSheetAnimated
{
    if (_actionsView.hidden || !_actionsView.superview)
        return;
    [UIView animateWithDuration:.3 animations:^{
        _quickActionPin.hidden = YES;
        _actionsView.frame = CGRectMake(OAUtilities.getLeftMargin, DeviceScreenHeight, _actionsView.bounds.size.width, _actionsView.bounds.size.height);
        [self restoreMapViewPort];
    } completion:^(BOOL finished) {
        [_actionsView removeFromSuperview];
    }];
    [_mapHudController showTopControls];
}

- (IBAction)quickActionButtonPressed:(id)sender
{
    if (!_actionsView)
    {
        _actionsView = [[OAQuickActionsSheetView alloc] init];
        _actionsView.delegate = self;
    }
    if (_actionsView.superview)
    {
        [self hideActionsSheetAnimated];
    }
    else
    {
        _actionsView.frame = CGRectMake(OAUtilities.getLeftMargin, DeviceScreenHeight, _actionsView.frame.size.width, _actionsView.frame.size.height);
        [UIView animateWithDuration:.3 animations:^{
            _quickActionPin.hidden = NO;
            [[UIApplication sharedApplication].keyWindow addSubview:_actionsView];
            [_actionsView layoutSubviews];
            _cachedYViewPort = [OARootViewController instance].mapPanel.mapViewController.mapView.viewportYScale;
            [self adjustMapViewPort];
        }];
        [self setPinPosition];
        [_mapHudController hideTopControls];
    }
}

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated];
}

@end
