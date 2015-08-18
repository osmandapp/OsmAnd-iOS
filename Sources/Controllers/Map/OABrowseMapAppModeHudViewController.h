//
//  OABrowseMapAppModeHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OADestinationViewController;
@class InfoWidgetsView;

@interface OABrowseMapAppModeHudViewController : UIViewController

@property (nonatomic) OADestinationViewController *destinationViewController;
@property (nonatomic) InfoWidgetsView *widgetsView;

@property (nonatomic, assign) BOOL contextMenuMode;

- (void)enterContextMenuMode;
- (void)restoreFromContextMenuMode;

- (void)showDestinations;
- (void)updateDestinationViewLayout:(BOOL)animated;

- (void)updateContextMenuToolbarLayout:(CGFloat)toolbarHeight animated:(BOOL)animated;

- (BOOL)isOverlayUnderlayViewVisible;
- (void)updateOverlayUnderlayView:(BOOL)show;

- (void)showTopControls;
- (void)hideTopControls;
- (void)showBottomControls:(CGFloat)menuHeight;
- (void)hideBottomControls:(CGFloat)menuHeight;

@end
