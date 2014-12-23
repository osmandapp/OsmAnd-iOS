//
//  OARootViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <JASidePanelController.h>

#import "OAMapPanelViewController.h"
#import "OAActionsPanelViewController.h"

@interface OARootViewController : JASidePanelController

@property (nonatomic, weak, readonly) OAMapPanelViewController* mapPanel;
@property (nonatomic, weak, readonly) OAActionsPanelViewController* actionsPanel;

- (void)openMenu:(UIViewController*)menuViewController
        fromRect:(CGRect)originRect
          inView:(UIView*)originView
        ofParent:(UIViewController*)parentViewController
        animated:(BOOL)animated;
- (void)closeMenuAnimated:(BOOL)animated;
@property(readonly) BOOL isMenuOpened;

- (void)closeMenuAndPanelsAnimated:(BOOL)animated;

- (BOOL)handleIncomingURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

- (void)showNoInternetAlert;
- (void)showNoInternetAlertFor:(NSString*)actionTitle;

+ (OARootViewController*)instance;

@end
