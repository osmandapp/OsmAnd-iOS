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
#import <AudioToolbox/AudioServices.h>
#import "OsmAnd_Maps-Swift.h"

static CGFloat const kHudButtonsOffset = 16.0;
static CGFloat const kHudQuickActionButtonHeight = 50.0;

static NSInteger const kQuickActionSlashTag = -1;
static NSInteger const kQuickActionSlashBackgroundTag = -2;
static NSInteger const kQuickActionSecondaryTag = -1;
static NSInteger const kQuickActionSecondaryBackgroundTag = -2;

@interface OAFloatingButtonsHudViewController () <OAQuickActionsSheetDelegate>

@property (weak, nonatomic) IBOutlet OAHudButton *map3dModeFloatingButton;
@property (weak, nonatomic) IBOutlet UIImageView *quickActionPin;

@end

@implementation OAFloatingButtonsHudViewController
{
    OAMapHudViewController *_mapHudController;
    OAAppSettings *_settings;
    OAMapButtonsHelper *_mapButtonsHelper;

    Map3DButtonState *_map3DButtonState;
    UILongPressGestureRecognizer *_map3dModeButtonDragRecognizer;

    OAQuickActionsSheetView *_actionsView;
    BOOL _isActionsViewVisible;
    NSMutableArray<OAHudButton *> *_quickActionFloatingButtons;

    CGFloat _cachedYViewPort;
    OAAutoObserverProxy *_map3dModeObserver;
    OAAutoObserverProxy *_applicationModeObserver;
    OAAutoObserverProxy *_actionsChangedObserver;
    OAAutoObserverProxy *_actionButtonsChangedObserver;
}

#pragma mark - Initialization

- (instancetype)initWithMapHudViewController:(OAMapHudViewController *)mapHudController
{
    self = [super initWithNibName:@"OAFloatingButtonsHudViewController" bundle:nil];
    if (self)
    {
        _mapHudController = mapHudController;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
    _map3DButtonState = [_mapButtonsHelper getMap3DButtonState];
    _isActionsViewVisible = NO;
    _quickActionFloatingButtons = [NSMutableArray array];
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
    if (_actionsChangedObserver)
    {
        [_actionsChangedObserver detach];
        _actionsChangedObserver = nil;
    }
    if (_actionButtonsChangedObserver)
    {
        [_actionButtonsChangedObserver detach];
        _actionButtonsChangedObserver = nil;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createQuickActionButtons];

    _map3dModeFloatingButton.tag = [OAUtilities getMap3DModeButtonTag];
    _map3dModeFloatingButton.alpha = 0;
    [_map3DButtonState.fabMarginPref restorePosition:_map3dModeFloatingButton];

    [self onMap3dModeUpdated];
    
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
                                                        withHandler:@selector(onQuickActionButtonChanged:withKey:)
                                                         andObserve:[OAMapButtonsHelper sharedInstance].quickActionsChangedObservable];
    _actionButtonsChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onQuickActionButtonChanged:withKey:andValue:)
                                                         andObserve:[OAMapButtonsHelper sharedInstance].quickActionButtonsChangedObservable];
    [self updateColors];
}

- (void)viewWillLayoutSubviews
{
    [self restoreControlsPosition];
    if (_actionsView.superview)
        [self adjustMapViewPort];
}

#pragma mark - Selectors

- (IBAction)quickActionButtonPressed:(OAHudButton *)sender
{
    if (sender.buttonState && [sender.buttonState isKindOfClass:QuickActionButtonState.class])
    {
        QuickActionButtonState *quickActionButtonState = (QuickActionButtonState *) sender.buttonState;
        if (quickActionButtonState.quickActions.count == 1)
        {
            BOOL isEnabled = [quickActionButtonState.quickActions.firstObject isActionWithSlash];
            [quickActionButtonState.quickActions.firstObject execute];
            [_mapButtonsHelper.quickActionsChangedObservable notifyEventWithKey:quickActionButtonState];
        }
        else
        {
            if (!_actionsView)
            {
                _actionsView = [[OAQuickActionsSheetView alloc] initWithButtonState:quickActionButtonState];
                _actionsView.delegate = self;
            }
            else if (![_actionsView.buttonState.id isEqualToString:quickActionButtonState.id])
            {
                [self hideActionsSheetAnimated:^{
                    _actionsView = [[OAQuickActionsSheetView alloc] initWithButtonState:quickActionButtonState];
                    _actionsView.delegate = self;
                    [self showActionsSheetAnimated:sender];
                }];
                return;
            }
            if (_actionsView.superview)
                [self hideActionsSheetAnimated:nil];
            else
                [self showActionsSheetAnimated:sender];
        }
    }
}

- (IBAction)map3dModeButtonPressed:(id)sender
{
    [OAMapViewTrackingUtilities.instance switchMap3dMode];
    [self onMap3dModeUpdated];
}

- (void)onQuickActionButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    if ([recognizer.view isKindOfClass:OAHudButton.class])
    {
        OAHudButton *quickActionButton = (OAHudButton *) recognizer.view;
        if (quickActionButton.buttonState && [quickActionButton.buttonState isKindOfClass:QuickActionButtonState.class])
        {
            [self onButtonDragged:recognizer
                           button:quickActionButton
              fabMarginPreference:((QuickActionButtonState *) quickActionButton.buttonState).fabMarginPref];
        }
    }
}

- (void)onMap3dModeButtonDragged:(UILongPressGestureRecognizer *)recognizer
{
    [self onButtonDragged:recognizer
                   button:_map3dModeFloatingButton
      fabMarginPreference:_map3DButtonState.fabMarginPref];
}

- (void)onButtonDragged:(UILongPressGestureRecognizer *)recognizer
                 button:(OAHudButton *)button
    fabMarginPreference:(FabMarginPreference *)fabMarginPreference
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

- (void)onMap3dModeUpdated
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
        Map3DModeVisibility map3DMode = [[[OAMapButtonsHelper sharedInstance] getMap3DButtonState] getVisibility];
        _map3dModeFloatingButton.accessibilityValue = [Map3DModeVisibilityWrapper getTitleForType:map3DMode];
    });
}

- (void)onApplicationModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateViewVisibility];
        [self restoreControlsPosition];
    });
}

- (void)onQuickActionButtonChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([key isKindOfClass:QuickActionButtonState.class])
        {
            QuickActionButtonState *quickActionButtonState = (QuickActionButtonState *) key;
            for (OAHudButton *quickActionButton in _quickActionFloatingButtons)
            {
                if ([quickActionButton.buttonState isKindOfClass:QuickActionButtonState.class])
                {
                    QuickActionButtonState *buttonState = (QuickActionButtonState *) quickActionButton.buttonState;
                    if ([buttonState.id isEqualToString:quickActionButtonState.id])
                    {
                        for (UIView *subview in quickActionButton.imageView.subviews)
                        {
                            if (subview.tag == kQuickActionSlashTag
                                || subview.tag == kQuickActionSlashBackgroundTag
                                || subview.tag == kQuickActionSecondaryTag
                                || subview.tag == kQuickActionSecondaryBackgroundTag)
                                [subview removeFromSuperview];
                        }
                        quickActionButton.buttonState = quickActionButtonState;
                        [self updateQuickActionButtonColors:quickActionButton];
                        break;
                    }
                }
            }
        }
    });
}

- (void)onQuickActionButtonChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!key && !value)
        {
            for (OAHudButton *button in _quickActionFloatingButtons)
            {
                [self updateQuickActionButtonColors:button];
                [self setupQuickActionBtnVisibility:button];
            }
        }
        else if ([key isKindOfClass:QuickActionButtonState.class] && [value isKindOfClass:NSNumber.class])
        {
            QuickActionButtonState *quickActionButtonState = (QuickActionButtonState *) key;
            BOOL isAdded = ((NSNumber *) value).boolValue;
            
            if (isAdded)
            {
                OAHudButton *button = [self createQuickActionFloatingButton:quickActionButtonState];
                [self updateQuickActionButtonColors:button];
                [self setupQuickActionBtnVisibility:button];
            }
            else
            {
                for (OAHudButton *button in _quickActionFloatingButtons)
                {
                    if ([button.buttonState isKindOfClass:QuickActionButtonState.class])
                    {
                        if ([((QuickActionButtonState *) button.buttonState).id isEqualToString:quickActionButtonState.id])
                        {
                            [button removeFromSuperview];
                            [_quickActionFloatingButtons removeObject:button];
                            break;
                        }
                    }
                }
            }
        }
    });
}

#pragma mark - Additions

- (QuickActionButtonState *)getActiveButtonState
{
    if (_isActionsViewVisible && _actionsView)
    {
        return _actionsView.buttonState;
    }
    return nil;
}

- (void)restorePinPosition
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
    for (OAHudButton *quickActionButton in _quickActionFloatingButtons)
    {
        [self updateQuickActionButtonColors:quickActionButton];
    }
    [self onMap3dModeUpdated];
}

- (void)updateQuickActionButtonColors:(OAHudButton *)quickActionButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [quickActionButton updateColorsForPressedState:NO];

        QuickActionButtonState *quickActionButtonState = nil;
        if (quickActionButton.buttonState && [quickActionButton.buttonState isKindOfClass:QuickActionButtonState.class])
            quickActionButtonState = ((QuickActionButtonState *) quickActionButton.buttonState);

        if (_isActionsViewVisible && _actionsView && [_actionsView.buttonState.id isEqualToString:quickActionButtonState.id])
        {
            [quickActionButton setImage:[UIImage templateImageNamed:@"ic_action_close_banner"] forState:UIControlStateNormal];
        }
        else
        {
            UIImage *quickActionIcon = quickActionButtonState ? [quickActionButtonState getIcon] : [UIImage templateImageNamed:@"ic_custom_quick_action"];
            [quickActionButton setImage:quickActionIcon forState:UIControlStateNormal];
            if (quickActionButtonState && [quickActionButtonState isSingleAction])
            {
                if (![quickActionButtonState.quickActions.firstObject isActionWithSlash])
                {
                    for (UIView *subview in quickActionButton.imageView.subviews)
                    {
                        if (subview.tag == kQuickActionSlashTag || subview.tag == kQuickActionSlashBackgroundTag)
                            [subview removeFromSuperview];
                    }
                }
                else
                {
                    CGRect frame = CGRectMake(0., 0., quickActionButton.imageView.frame.size.width, quickActionButton.imageView.frame.size.height);
                    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:@"ic_custom_compound_action_hide_bottom"]];
                    background.tag = kQuickActionSlashBackgroundTag;
                    background.frame = frame;
                    [background setTintColor:!_settings.nightMode ? UIColorFromRGB(color_quick_action_background) : UIColorFromRGB(color_quick_action_background_night)];
                    [quickActionButton.imageView addSubview:background];

                    UIImageView *slash = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:@"ic_custom_compound_action_hide_top"]];
                    slash.tag = kQuickActionSlashTag;
                    slash.frame = frame;
                    [quickActionButton.imageView addSubview:slash];
                }
                if (![quickActionButtonState.quickActions.firstObject hasSecondaryIcon])
                {
                    for (UIView *subview in quickActionButton.imageView.subviews)
                    {
                        if (subview.tag == kQuickActionSecondaryTag || subview.tag == kQuickActionSecondaryBackgroundTag)
                            [subview removeFromSuperview];
                    }
                }
                else
                {
                    CGRect frame = CGRectMake(0., 0., quickActionButton.imageView.frame.size.width, quickActionButton.imageView.frame.size.height);
                    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:@"ic_custom_compound_action_background"]];
                    background.tag = kQuickActionSecondaryBackgroundTag;
                    [background setTintColor:!_settings.nightMode ? UIColorFromRGB(color_quick_action_background) : UIColorFromRGB(color_quick_action_background_night)];
                    [quickActionButton.imageView addSubview:background];

                    NSString *secondaryIcon = [quickActionButtonState.quickActions.firstObject getSecondaryIconName];
                    UIImageView *add = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:secondaryIcon]];
                    add.tag = kQuickActionSecondaryTag;
                    add.frame = frame;
                    [quickActionButton.imageView addSubview:add];
                }
            }
        }
    });
}

- (void)createQuickActionButtons
{
    for (QuickActionButtonState *quickActionButtonState in [_mapButtonsHelper getButtonsStates])
    {
        [self createQuickActionFloatingButton:quickActionButtonState];
    }
}

- (OAHudButton *)createQuickActionFloatingButton:(QuickActionButtonState *)quickActionButtonState
{
    OAHudButton *quickActionButton = [[OAHudButton alloc] initWithFrame:{346, 648, 50, 50}];
    [_quickActionFloatingButtons addObject:quickActionButton];
    [self.view addSubview:quickActionButton];

    quickActionButton.buttonState = quickActionButtonState;
    quickActionButton.tag = [OAUtilities getQuickActionButtonTag];
    quickActionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    quickActionButton.alpha = [quickActionButtonState isEnabled] ? 1 : 0;
    quickActionButton.userInteractionEnabled = [quickActionButtonState isEnabled];
    quickActionButton.accessibilityLabel = OALocalizedString(@"configure_screen_quick_action");
    quickActionButton.tintColorDay = UIColorFromRGB(color_primary_purple);
    quickActionButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
    [quickActionButton updateColorsForPressedState:NO];
    [quickActionButton addTarget:self action:@selector(quickActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    UILongPressGestureRecognizer *quickActionsButtonDragRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onQuickActionButtonDragged:)];
    [quickActionsButtonDragRecognizer setMinimumPressDuration:0.5];
    [quickActionButton addGestureRecognizer:quickActionsButtonDragRecognizer];
    [quickActionButtonState.fabMarginPref restorePosition:quickActionButton];
    return quickActionButton;
}

- (void)adjustMapViewPort
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL isLandscape = [OAUtilities isLandscape];
    [mapPanel.mapViewController setViewportScaleX:isLandscape ? kViewportBottomScale : kViewportScale
                                                y:isLandscape ? kViewportScale : (DeviceScreenHeight - _actionsView.frame.size.height) / DeviceScreenHeight];
}

- (void)restoreMapViewPort
{
    [[OARootViewController instance].mapPanel.mapViewController setViewportScaleX:kViewportScale y:_cachedYViewPort];
}

- (void)updateViewVisibility
{
    for (OAHudButton *quickActionButton in _quickActionFloatingButtons)
    {
        [self setupQuickActionBtnVisibility:quickActionButton];
    }
    [self setupMap3dModeButtonVisibility];
}

- (void)setupQuickActionBtnVisibility:(OAHudButton *)quickActionButton
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL hideQuickButton = (quickActionButton.buttonState
                            && [quickActionButton.buttonState isKindOfClass:QuickActionButtonState.class]
                            && ![((QuickActionButtonState *) quickActionButton.buttonState) isEnabled])
        || [mapPanel isContextMenuVisible]
        || [mapPanel isDashboardVisible]
        || [mapPanel gpxModeActive]
        || [mapPanel isRouteInfoVisible]
        || mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;

    [UIView animateWithDuration:.25 animations:^{
        quickActionButton.alpha = hideQuickButton ? 0 : 1;
    } completion:^(BOOL finished) {
        quickActionButton.userInteractionEnabled = !hideQuickButton;
    }];
}

- (void)setupMap3dModeButtonVisibility
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;

    Map3DModeVisibility map3DMode = [_map3DButtonState getVisibility];
    BOOL hideButton = map3DMode == Map3DModeVisibilityHidden
        || (map3DMode == Map3DModeVisibilityVisibleIn3DMode
            && ![OAMapViewTrackingUtilities.instance is3DMode])
        || [mapPanel isContextMenuVisible]
        || [mapPanel isDashboardVisible]
        || [mapPanel gpxModeActive]
        || [mapPanel isRouteInfoVisible]
        || mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
    
    [UIView animateWithDuration:.25 animations:^{
        _map3dModeFloatingButton.alpha = hideButton ? 0 : 1;
    } completion:^(BOOL finished) {
        _map3dModeFloatingButton.userInteractionEnabled = !hideButton;
    }];
}

- (BOOL)isQuickActionButtonVisible
{
    for (OAHudButton *quickActionButton in _quickActionFloatingButtons)
    {
        if (quickActionButton.alpha == 1)
            return YES;
    }
    return NO;
}

- (void)restoreControlsPosition 
{
    for (OAHudButton *quickActionButton in _quickActionFloatingButtons)
    {
        if (quickActionButton.buttonState && [quickActionButton.buttonState isKindOfClass:QuickActionButtonState.class])
        {
            QuickActionButtonState *quickActionButtonState = ((QuickActionButtonState *) quickActionButton.buttonState);
            [quickActionButtonState.fabMarginPref restorePosition:quickActionButton];
        }
    }
    [_map3DButtonState.fabMarginPref restorePosition:_map3dModeFloatingButton];
    [self restorePinPosition];
}

- (BOOL)isActionSheetVisible
{
    return _isActionsViewVisible;
}

- (void)showActionsSheetAnimated:(OAHudButton *)quickActionButton
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
    [self updateQuickActionButtonColors:quickActionButton];
}

- (void)hideActionsSheetAnimated:(void (^)(void))completion
{
    if (_actionsView.hidden || !_actionsView.superview)
    {
        if (completion)
            completion();
        return;
    }

    _isActionsViewVisible = NO;
    [UIView animateWithDuration:.3 animations:^{
        [_actionsView hide];
        _quickActionPin.hidden = YES;
        [self restoreMapViewPort];
    } completion:^(BOOL finished) {
        [_mapHudController updateControlsLayout:YES];
        _actionsView = nil;
        if (completion)
            completion();
    }];
    [self updateColors];
}

#pragma mark - OAQuickActionBottomSheetDelegate

- (void)dismissBottomSheet
{
    [self hideActionsSheetAnimated:nil];
}

@end
