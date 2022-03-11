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
#import "OAHudButton.h"

#import <AudioToolbox/AudioServices.h>

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f
#define kHudButtonsOffset 16.0f
#define kHudQuickActionButtonHeight 50.0f

@interface OAQuickActionHudViewController () <OAQuickActionsSheetDelegate>

@property (weak, nonatomic) IBOutlet OAHudButton *quickActionFloatingButton;
@property (weak, nonatomic) IBOutlet UIImageView *quickActionPin;

@end

@implementation OAQuickActionHudViewController
{
    OAMapHudViewController *_mapHudController;
    
    OAAppSettings *_settings;
    
    UILongPressGestureRecognizer *_buttonDragRecognizer;
    OAQuickActionsSheetView *_actionsView;
    BOOL _isActionsViewVisible;
    
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
    [self updateColors:NO];
    
    _buttonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonDragged:)];
    [_buttonDragRecognizer setMinimumPressDuration:0.5];
    [_quickActionFloatingButton addGestureRecognizer:_buttonDragRecognizer];
    
    [self setQuickActionButtonMargin];
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

- (void) updateViewVisibilityAnimated:(BOOL)isAnimated
{
    [self setupQuickActionBtnVisibilityAnimated:isAnimated];
}

- (void) setupQuickActionBtnVisibility
{
    [self setupQuickActionBtnVisibilityAnimated:YES];
}

- (void) setupQuickActionBtnVisibilityAnimated:(BOOL)isAnimated
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    //    contextMenuLayer.isInChangeMarkerPositionMode() ||
    //    measurementToolLayer.isInMeasurementMode() ||
    BOOL hideQuickButton = ![_settings.quickActionIsOn get] ||
    [mapPanel isContextMenuVisible] ||
    [mapPanel gpxModeActive] ||
    [mapPanel isRouteInfoVisible];
    
    [UIView animateWithDuration:.25 animations:^{
        _quickActionFloatingButton.alpha = hideQuickButton ? 0 : 1;
        if (isAnimated)
        {
            [self setQuickActionButtonMargin];
            if (hideQuickButton)
            {
                _quickActionFloatingButton.frame = CGRectMake(_quickActionFloatingButton.frame.origin.x + DeviceScreenWidth, _quickActionFloatingButton.frame.origin.y, _quickActionFloatingButton.frame.size.width, _quickActionFloatingButton.frame.size.height);
            }
        }
    } completion:^(BOOL finished) {
        _quickActionFloatingButton.userInteractionEnabled = !hideQuickButton;
    }];
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
        [self setQuickActionButtonPosition:x y:y defaultX:defaultX defaultY:defaultY];
    }
    else
    {
        defaultX = maxRightMargin - kHudButtonsOffset;
        defaultY = maxBottomMargin - 2 * btnWidth - 2 * kHudButtonsOffset;
        x = [_settings.quickActionPortraitX get];
        y = [_settings.quickActionPortraitY get];
        [self setQuickActionButtonPosition:x y:y defaultX:defaultX defaultY:defaultY];
    }
}

- (void) setQuickActionButtonPosition:(CGFloat)x y:(CGFloat)y defaultX:(CGFloat)defaultX defaultY:(CGFloat)defaultY
{
    CGFloat screenHeight = DeviceScreenHeight;
    CGFloat screenWidth = DeviceScreenWidth;
    CGFloat btnHeight = _quickActionFloatingButton.frame.size.height;
    CGFloat btnWidth = _quickActionFloatingButton.frame.size.width;
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
    
    _quickActionFloatingButton.frame = CGRectMake(x, y, btnWidth, btnHeight);
}

- (void)viewWillLayoutSubviews
{
    [self setQuickActionButtonMargin];
    [self setPinPosition];
    if (_actionsView.superview)
        [self adjustMapViewPort];
}

- (void)moveToPoint:(CGPoint)newPosition
{
    CGSize bigButtonSize = _quickActionFloatingButton.frame.size;
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
    
    _quickActionFloatingButton.frame = CGRectMake(x - halfBigButtonWidth, y - halfBigButtonWidth, _quickActionFloatingButton.frame.size.width, _quickActionFloatingButton.frame.size.height);
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

- (void)showActionsSheetAnimated
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
    _isActionsViewVisible = YES;
    [self updateColors:NO];
}

- (void)hideActionsSheetAnimated
{
    if (_actionsView.hidden || !_actionsView.superview)
        return;
    
        [_mapHudController showTopControls:NO];
    
    [UIView animateWithDuration:.3 animations:^{
        _quickActionPin.hidden = YES;
        _actionsView.frame = CGRectMake(OAUtilities.getLeftMargin, DeviceScreenHeight, _actionsView.bounds.size.width, _actionsView.bounds.size.height);
        [self restoreMapViewPort];
    } completion:^(BOOL finished) {
        [_actionsView removeFromSuperview];
        [_mapHudController showTopControls:NO];
    }];
    _isActionsViewVisible = NO;
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

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated];
}

@end
