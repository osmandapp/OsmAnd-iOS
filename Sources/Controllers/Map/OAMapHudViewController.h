//
//  OAMapHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapModeHeaders.h"

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
@property (weak, nonatomic) IBOutlet UIButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;

@property (weak, nonatomic) IBOutlet UIView *widgetsView;
@property (weak, nonatomic) IBOutlet UIView *leftWidgetsView;
@property (weak, nonatomic) IBOutlet UIView *rightWidgetsView;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;

@property (weak, nonatomic) IBOutlet UIButton *mapSettingsButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@property (weak, nonatomic) IBOutlet UIButton *mapModeButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomOutButton;
@property (weak, nonatomic) IBOutlet UIView *zoomButtonsView;

@property (weak, nonatomic) IBOutlet UIButton *driveModeButton;
@property (weak, nonatomic) IBOutlet UIButton *debugButton;
@property (weak, nonatomic) IBOutlet UITextField *searchQueryTextfield;
@property (weak, nonatomic) IBOutlet UIButton *optionsMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *actionsMenuButton;

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

- (void) showTopControls;
- (void) hideTopControls;
- (void) showBottomControls:(CGFloat)menuHeight animated:(BOOL)animated;
- (void) hideBottomControls:(CGFloat)menuHeight animated:(BOOL)animated;
- (CGFloat) getControlsTopPosition;

- (void) onRoutingProgressChanged:(int)progress;
- (void) onRoutingProgressFinished;

- (void) updateRouteButton:(BOOL)routePlanningMode followingMode:(BOOL)followingMode;

- (void) recreateControls;
- (void) updateInfo;

@end
