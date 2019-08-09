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
#import "OAQuickActionsSheetView.h"
#import "OAColors.h"

#import <AudioToolbox/AudioServices.h>

@interface OAQuickActionHudViewController () <OAQuickActionsSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *quickActionFloatingButton;

@end

@implementation OAQuickActionHudViewController
{
    OAMapHudViewController *_mapHudController;
    
    OAAppSettings *_settings;
    
    UILongPressGestureRecognizer *_buttonDragRecognizer;
    OAQuickActionsSheetView *_actionsView;
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
    
    [_quickActionFloatingButton setTintColor:UIColorFromRGB(color_primary_purple)];
    [_quickActionFloatingButton setImage:[[UIImage imageNamed:@"ic_custom_quick_action"]
                                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                forState:UIControlStateNormal];
    _quickActionFloatingButton.hidden = ![_settings.quickActionIsOn get];
    
    _buttonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonDragged:)];
    [_buttonDragRecognizer setMinimumPressDuration:0.5];
    [_quickActionFloatingButton addGestureRecognizer:_buttonDragRecognizer];
    
    [self setQuickActionButtonPosition];
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
        x = _settings.quickActionLandscapeX;
        y = _settings.quickActionLandscapeY;
    }
    else
    {
        x = _settings.quickActionPortraitX;
        y = _settings.quickActionPortraitY;
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
}

- (void)moveToPoint:(CGPoint)newPosition
{
    CGSize size = _quickActionFloatingButton.frame.size;
    _quickActionFloatingButton.frame = CGRectMake(newPosition.x - size.width / 2, newPosition.y - size.height / 2, _quickActionFloatingButton.frame.size.width, _quickActionFloatingButton.frame.size.height);
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
    [UIView animateWithDuration:.3 animations:^{
        _actionsView.frame = CGRectMake(OAUtilities.getLeftMargin, DeviceScreenHeight, _actionsView.bounds.size.width, _actionsView.bounds.size.height);
    } completion:^(BOOL finished) {
        [_actionsView removeFromSuperview];
    }];
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
            [[UIApplication sharedApplication].keyWindow addSubview:_actionsView];
            [_actionsView layoutSubviews];
        }];
    }
}

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated];
}

@end
