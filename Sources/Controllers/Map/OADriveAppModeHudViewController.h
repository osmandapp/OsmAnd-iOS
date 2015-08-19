//
//  OADriveAppModeHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OADestinationViewController;
@class InfoWidgetsView;

@interface OADriveAppModeHudViewController : UIViewController

@property (nonatomic) OADestinationViewController *destinationViewController;
@property (nonatomic) InfoWidgetsView *widgetsView;

@property (nonatomic, assign) BOOL contextMenuMode;
@property (nonatomic, assign) BOOL showGoToMapButton;

- (void)enterContextMenuMode;
- (void)restoreFromContextMenuMode;

- (void)showDestinations;
- (void)updateDestinationViewLayout:(BOOL)animated;

- (void)updateContextMenuToolbarLayout:(CGFloat)toolbarHeight animated:(BOOL)animated;

- (void)showTopControls;
- (void)hideTopControls;
- (void)showBottomControls:(CGFloat)menuHeight;
- (void)hideBottomControls:(CGFloat)menuHeight;

@end
