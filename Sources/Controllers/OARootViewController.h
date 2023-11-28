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

#define kLeftPannelGestureRecognizer @"kLeftPannelGestureRecognizer"

#define kCommandSearchScreenOpen @"keyCommandSearchScreenOpen"
#define kCommandSearchScreenClose @"keyCommandSearchScreenClose"
#define kCommandNavigationScreenOpen @"keyCommandNavigationScreenOpen"
#define kCommandNavigationScreenClose @"keyCommandNavigationScreenClose"

@class OAProduct;

@interface OARootViewController : JASidePanelController

@property (nonatomic, weak, readonly) OAMapPanelViewController* mapPanel;
@property(readonly) BOOL isMenuOpened;
@property (nonatomic) NSString *token;

@property (readonly) OAAutoObserverProxy *keyCommandUpdateObserver;

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
- (void) importAsFavorites:(NSURL *)url;
- (void) importAsGPX:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView;

+ (void) showInfoAlertWithTitle:(NSString *)title
                        message:(NSString *)message
                   inController:(UIViewController *)controller;

- (void) showNoInternetAlert;
- (void) showNoInternetAlertFor:(NSString*)actionTitle;

- (BOOL) buyProduct:(OAProduct *)product showProgress:(BOOL)showProgress;
- (BOOL) restorePurchasesWithProgress:(BOOL)showProgress;
- (BOOL) requestProductsWithProgress:(BOOL)showProgress reload:(BOOL)reload;
- (BOOL) requestProductsWithProgress:(BOOL)showProgress reload:(BOOL)reload restorePurchases:(BOOL)restore;

- (void) openSafariWithURL:(NSString *)urlString;

- (void)updateLeftPanelMenu;

@end
