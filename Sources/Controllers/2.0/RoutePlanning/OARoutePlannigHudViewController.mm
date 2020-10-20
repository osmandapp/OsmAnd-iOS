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

@interface OARoutePlannigHudViewController () <OADraggableViewDelegate>

@property (strong, nonatomic) IBOutlet OAScrollableTableToolBarView *scrollableView;

@end

@implementation OARoutePlannigHudViewController
{
    OAAppSettings *_settings;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OARoutePlannigHudViewController"
                           bundle:nil];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scrollableView.delegate = self;
    [_scrollableView show:YES onComplete:nil];
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel setTopControlsVisible:NO customStatusBarStyle:isNight ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    [mapPanel setBottomControlsVisible:NO menuHeight:0 animated:YES];
}

- (void)adjustMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
}

- (void) restoreMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
}

- (void) updateViewVisibility
{

}

- (void)viewWillLayoutSubviews
{
}

#pragma mark - OADraggableViewDelegate

- (void)onViewSwippedDown
{
    // TODO: implement custom behavior to prevent swipe down
    [_scrollableView hide:YES duration:.2 onComplete:^{
            [self.view removeFromSuperview];
    }];
}

- (void)onViewHeightChanged:(CGFloat)height
{
    
}

@end
