//
//  OAMapHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapModeHeaders.h"
#import "OAHudButton.h"

@class OAQuickActionHudViewController;
@class OAToolbarViewController;
@class OAMapRulerView;
@class OAMapInfoController;
@class OATopCoordinatesWidget;

@interface OAMapHudViewController : UIViewController

@property (nonatomic, readonly) EOAMapHudType mapHudType;
@property (nonatomic) OAQuickActionHudViewController *quickActionController;

@property (weak, nonatomic) IBOutlet UIView *statusBarView;

@property (weak, nonatomic) IBOutlet UIView *compassBox;
@property (weak, nonatomic) IBOutlet OAHudButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;

@property (weak, nonatomic) IBOutlet UIView *widgetsView;
@property (weak, nonatomic) IBOutlet UIView *leftWidgetsView;
@property (weak, nonatomic) IBOutlet UIView *rightWidgetsView;

@property (weak, nonatomic) IBOutlet OAHudButton *mapSettingsButton;
@property (weak, nonatomic) IBOutlet OAHudButton *searchButton;

@property (weak, nonatomic) IBOutlet OAHudButton *mapModeButton;
@property (weak, nonatomic) IBOutlet OAHudButton *zoomInButton;
@property (weak, nonatomic) IBOutlet OAHudButton *zoomOutButton;
@property (weak, nonatomic) IBOutlet UIView *zoomButtonsView;

@property (weak, nonatomic) IBOutlet OAHudButton *driveModeButton;
@property (weak, nonatomic) IBOutlet UITextField *searchQueryTextfield;
@property (weak, nonatomic) IBOutlet OAHudButton *optionsMenuButton;

@property (strong, nonatomic) IBOutlet OAMapRulerView *rulerLabel;

@property (nonatomic) OAToolbarViewController *toolbarViewController;
@property (nonatomic) OAMapInfoController *mapInfoController;
@property (nonatomic) OATopCoordinatesWidget *topCoordinatesWidget;

@property (nonatomic, assign) BOOL contextMenuMode;
@property (nonatomic, assign) EOAMapModeButtonType mapModeButtonType;

@property (nonatomic, readonly) CGFloat toolbarTopPosition;

- (void) enterContextMenuMode;
- (void) restoreFromContextMenuMode;
- (void) updateRulerPosition:(CGFloat)bottom left:(CGFloat)left;

- (void) setToolbar:(OAToolbarViewController *)toolbarController;
- (void) updateToolbarLayout:(BOOL)animated;
- (void) removeToolbar;

- (void) setCoordinatesWidget:(OATopCoordinatesWidget *)widget;

- (void) updateContextMenuToolbarLayout:(CGFloat)toolbarHeight animated:(BOOL)animated;

- (BOOL) isOverlayUnderlayViewVisible;
- (void) updateOverlayUnderlayView;

- (void) setTopControlsAlpha:(CGFloat)alpha;
- (void) showTopControls;
- (void) hideTopControls;
- (void) showBottomControls:(CGFloat)menuHeight animated:(BOOL)animated;
- (void) hideBottomControls:(CGFloat)menuHeight animated:(BOOL)animated;
- (CGFloat) getHudButtonsMinTopOffset;
- (CGFloat) getHudButtonsTopOffset;

- (void) onRoutingProgressChanged:(int)progress;
- (void) onRoutingProgressFinished;

- (void) updateRouteButton:(BOOL)routePlanningMode followingMode:(BOOL)followingMode;

- (void) recreateControls;
- (void) updateInfo;

@end
