//
//  OAMapHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapModeHeaders.h"

@class OAToolbarViewController;
@class InfoWidgetsView;

@interface OAMapHudViewController : UIViewController

@property (nonatomic, readonly) EOAMapHudType mapHudType;

@property (nonatomic) OAToolbarViewController *toolbarViewController;
//@property (nonatomic) InfoWidgetsView *widgetsView;
@property (nonatomic) NSArray<UIView *> *widgets;

@property (nonatomic, assign) BOOL contextMenuMode;
@property (nonatomic, assign) EOAMapModeButtonType mapModeButtonType;

@property (nonatomic, readonly) CGFloat toolbarTopPosition;

- (void) enterContextMenuMode;
- (void) restoreFromContextMenuMode;

- (void) setToolbar:(OAToolbarViewController *)toolbarController;
- (void) updateToolbarLayout:(BOOL)animated;
- (void) removeToolbar;

- (void) updateContextMenuToolbarLayout:(CGFloat)toolbarHeight animated:(BOOL)animated;

- (BOOL) isOverlayUnderlayViewVisible;
- (void) updateOverlayUnderlayView:(BOOL)show;

- (void) showTopControls;
- (void) hideTopControls;
- (void) showBottomControls:(CGFloat)menuHeight;
- (void) hideBottomControls:(CGFloat)menuHeight;

- (void) onRoutingProgressChanged:(int)progress;
- (void) onRoutingProgressFinished;

- (void) updateRouteButton:(BOOL)routePlanningMode;

- (void) recreateControls;

@end
