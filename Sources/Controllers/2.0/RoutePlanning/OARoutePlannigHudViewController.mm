//
//  OARoutePlannigHudViewController.m
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoutePlannigHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAScrollableTableToolBarView.h"
#import "OAColors.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@interface OARoutePlannigHudViewController () <OADraggableViewDelegate>

@property (strong, nonatomic) IBOutlet OAScrollableTableToolBarView *scrollableView;
@property (weak, nonatomic) IBOutlet UIImageView *centerImageView;
@property (weak, nonatomic) IBOutlet UIView *closeButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@end

@implementation OARoutePlannigHudViewController
{
    OAAppSettings *_settings;
    
    OAMapPanelViewController *_mapPanel;
    
    CGFloat _cachedYViewPort;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OARoutePlannigHudViewController"
                           bundle:nil];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _mapPanel = OARootViewController.instance.mapPanel;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scrollableView.delegate = self;
    [_scrollableView show:YES state:EOADraggableMenuStateInitial onComplete:nil];
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    [_mapPanel setTopControlsVisible:NO customStatusBarStyle:UIStatusBarStyleLightContent];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:_scrollableView.getViewHeight animated:YES];
    _centerImageView.image = [UIImage imageNamed:@"ic_ruler_center.png"];
    [self changeCenterOffset:[_scrollableView getViewHeight]];
    
    _closeButtonContainerView.layer.cornerRadius = 12.;
    _doneButtonContainerView.layer.cornerRadius = 12.;
    
    [_closeButton setImage:[[UIImage imageNamed:@"ic_navbar_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _closeButton.imageView.tintColor = UIColor.whiteColor;
    
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    _titleView.text = OALocalizedString(@"plan_route");
    
    [self adjustMapViewPort];
}

- (void) changeCenterOffset:(CGFloat)contentHeight
{
    _centerImageView.center = CGPointMake(self.view.frame.size.width * 0.5,
                                    self.view.frame.size.height * 0.5 - contentHeight / 2);
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
        mapView.viewportYScale = _scrollableView.getViewHeight / DeviceScreenHeight;
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

}

- (void)viewWillLayoutSubviews
{
}
- (IBAction)closePressed:(id)sender
{
    [_scrollableView hide:YES duration:.2 onComplete:^{
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
    }];
}

- (IBAction)donePressed:(id)sender
{
}

#pragma mark - OADraggableViewDelegate

- (void)onViewSwippedDown
{
    [_scrollableView hide:YES duration:.2 onComplete:^{
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
    }];
}

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeCenterOffset:height];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:height animated:YES];
    [self adjustMapViewPort];
}

@end
