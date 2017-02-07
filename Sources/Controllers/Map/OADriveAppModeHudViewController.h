//
//  OADriveAppModeHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapModeHeaders.h"

@class OAToolbarViewController;
@class InfoWidgetsView;

@interface OADriveAppModeHudViewController : UIViewController

@property (nonatomic, readonly) EOAMapHudType mapHudType;

@property (nonatomic) OAToolbarViewController *toolbarViewController;
@property (nonatomic) InfoWidgetsView *widgetsView;

@property (nonatomic, assign) BOOL contextMenuMode;
@property (nonatomic, assign) EOAMapModeButtonType mapModeButtonType;

@property (nonatomic, readonly) CGFloat toolbarTopPosition;

- (void)enterContextMenuMode;
- (void)restoreFromContextMenuMode;

- (void)setToolbar:(OAToolbarViewController *)toolbarController;
- (void)updateToolbarLayout:(BOOL)animated;
- (void)removeToolbar;

- (void)updateContextMenuToolbarLayout:(CGFloat)toolbarHeight animated:(BOOL)animated;

- (void)showTopControls;
- (void)hideTopControls;
- (void)showBottomControls:(CGFloat)menuHeight;
- (void)hideBottomControls:(CGFloat)menuHeight;

@end
