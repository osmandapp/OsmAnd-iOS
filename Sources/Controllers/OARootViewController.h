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

@class OAProduct;

@interface OARootViewController : JASidePanelController

@property (nonatomic, weak, readonly) OAMapPanelViewController* mapPanel;
@property(readonly) BOOL isMenuOpened;

+ (OARootViewController*) instance;

- (void) openMenu:(UIViewController*)menuViewController
         fromRect:(CGRect)originRect
           inView:(UIView*)originView
         ofParent:(UIViewController*)parentViewController
         animated:(BOOL)animated;

- (void) closeMenuAnimated:(BOOL)animated;
- (void) closeMenuAndPanelsAnimated:(BOOL)animated;
- (void) restoreCenterPanel:(UIViewController *)viewController;

- (BOOL) handleIncomingURL:(NSURL *)url;

- (void) showNoInternetAlert;
- (void) showNoInternetAlertFor:(NSString*)actionTitle;

- (BOOL) buyProduct:(OAProduct *)product showProgress:(BOOL)showProgress;
- (BOOL) restorePurchasesWithProgress:(BOOL)showProgress;
- (BOOL) requestProductsWithProgress:(BOOL)showProgress reload:(BOOL)reload;

@end
