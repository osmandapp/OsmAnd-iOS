//
//  OARootViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OARootViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <JASidePanelController.h>
#import <UIAlertView+Blocks.h>
#import <MBProgressHUD.h>
#import <Reachability.h>

#import "OAAppDelegate.h"
#import "OAMenuOriginViewControllerProtocol.h"
#import "OAMenuViewControllerProtocol.h"
#import "OAFavoriteImportViewController.h"
#import "OANavigationController.h"
#import "OAOptionsPanelBlackViewController.h"
#import "OAGPXListViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAIAPHelper.h"
#import "OADonationSettingsViewController.h"
#import "OAChoosePlanHelper.h"

#import "Localization.h"

#define _(name) OARootViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

typedef enum : NSUInteger {
    EOARequestProductsProgressType,
    EOAPurchaseProductProgressType,
    EOARestorePurchasesProgressType,
} EOAProgressType;

@interface OARootViewController () <UIPopoverControllerDelegate>
@end

@implementation OARootViewController
{
    UIViewController* __weak _lastMenuOriginViewController;
    UIPopoverController* _lastMenuPopoverController;
    UIViewController* __weak _lastMenuViewController;
    
    OAIAPHelper *_iapHelper;
    MBProgressHUD *_requestProgressHUD;
    MBProgressHUD *_purchaseProgressHUD;
    MBProgressHUD *_restoreProgressHUD;
    BOOL _productsRequestNeeded;
    BOOL _productsRequestWithProgress;
    BOOL _productsRequestReload;
    BOOL _restoringPurchases;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _iapHelper = [OAIAPHelper sharedInstance];
    
    // Create panels:
    [self setLeftPanel:[[OAOptionsPanelBlackViewController alloc] initWithNibName:@"OptionsPanel" bundle:nil]];
    [self setCenterPanel:[[OAMapPanelViewController alloc] init]];
    //[self setRightPanel:[[OAActionsPanelViewController alloc] init]];
}

+ (OARootViewController*) instance
{
    OAAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.rootViewController;
}

- (void) restoreCenterPanel:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
    
    [self addChildViewController:viewController];
    [self.centerPanelContainer insertSubview:viewController.view atIndex:0];
    [viewController didMoveToParentViewController:self];
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view.backgroundColor = UIColor.whiteColor;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
    // 80% of smallest device width in portait mode (320 points)
    self.leftFixedWidth = kDrawerWidth;
    self.rightFixedWidth = kDrawerWidth;
    self.shouldResizeLeftPanel = NO;
    self.shouldResizeRightPanel = YES;
    
    // Initially disallow pan gesture to exclude interference with map
    // (it should be enabled after side panel is shown until it's not hidden)
    self.recognizesPanGesture = NO;
    self.panningLimitedToTopViewController = NO;
    
    // Allow rotation, without respect to current active panel
    self.shouldDelegateAutorotateToVisiblePanel = NO;
    
    self.navigationController.navigationBarHidden = YES;
    
    //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseDeferred:) name:OAIAPProductPurchaseDeferredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestPurchase:) name:OAIAPRequestPurchaseProductNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (BOOL) prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    if (self.isMenuOpened)
        return _lastMenuViewController.preferredStatusBarStyle;

    if (self.state == JASidePanelLeftVisible)
        return self.leftPanel.preferredStatusBarStyle;
    else if (self.state == JASidePanelRightVisible)
        return self.rightPanel.preferredStatusBarStyle;

    return self.centerPanel.preferredStatusBarStyle;
}

- (void) styleContainer:(UIView *)container animate:(BOOL)animate duration:(NSTimeInterval)duration
{
    // For iOS 7.0+ disable casting shadow. Instead use border for left and right panels
    container.clipsToBounds = NO;
    
    if (container == self.centerPanelContainer)
    {
        //
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) stylePanel:(UIView *)panel
{
    [super stylePanel:panel];
    
    // Setting corner radius on EGL layer will drop (or better to say, cap) framerate to 40 fps
    panel.layer.cornerRadius = 0.0f;
}

- (OAMapPanelViewController *) mapPanel
{
    return (OAMapPanelViewController*)self.centerPanel;
}

- (void) openMenu:(UIViewController*)menuViewController
         fromRect:(CGRect)originRect
           inView:(UIView *)originView
         ofParent:(UIViewController *)parentViewController
         animated:(BOOL)animated
{
    // Save reference to origin
    if ([menuViewController conformsToProtocol:@protocol(OAMenuViewControllerProtocol)])
        ((id<OAMenuViewControllerProtocol>)menuViewController).menuOriginViewController = parentViewController;
    _lastMenuOriginViewController = parentViewController;
    _lastMenuViewController = menuViewController;

    [self.navigationController pushViewController:menuViewController
                                         animated:animated];

    /*
    // Open menu actually
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // For iPhone and iPod, push menu to navigation controller
        [self.navigationController pushViewController:menuViewController
                                             animated:animated];
    }
    else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // For iPad, open menu in a popover with it's own navigation controller
        UINavigationController* popoverNavigationController = [[OANavigationController alloc] initWithRootViewController:menuViewController];
        _lastMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:popoverNavigationController];
        _lastMenuPopoverController.delegate = self;

        [_lastMenuPopoverController presentPopoverFromRect:originRect
                                                    inView:originView
                                  permittedArrowDirections:UIPopoverArrowDirectionAny
                                                  animated:animated];
    }
     */

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) closeMenuAnimated:(BOOL)animated
{
    if (!self.isMenuOpened)
        return;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if ([self.navigationController.viewControllers containsObject:_lastMenuOriginViewController])
        {
            [self.navigationController popToViewController:_lastMenuOriginViewController
                                                  animated:animated];
        }
        else
        {
            NSArray* viewControllers = self.navigationController.viewControllers;
            NSUInteger menuIndex = [viewControllers indexOfObject:_lastMenuViewController];
            if (menuIndex == 0)
                [self.navigationController popToRootViewControllerAnimated:animated];
            else
            {
                [self.navigationController popToViewController:[viewControllers objectAtIndex:menuIndex-1]
                                                      animated:animated];
            }
        }

        if ([_lastMenuOriginViewController conformsToProtocol:@protocol(OAMenuOriginViewControllerProtocol)])
        {
            id<OAMenuOriginViewControllerProtocol> origin = (id<OAMenuOriginViewControllerProtocol>)_lastMenuOriginViewController;
            [origin notifyMenuClosed];
        }
    }
    else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if (_lastMenuPopoverController != nil)
            [_lastMenuPopoverController dismissPopoverAnimated:animated];
        
        [self popoverControllerDidDismissPopover:_lastMenuPopoverController];
    }

    _lastMenuOriginViewController = nil;
    _lastMenuViewController = nil;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL) isMenuOpened
{
    if (_lastMenuViewController == nil)
        return NO;

    // For iPhone/iPod devices check that mentioned view controller is still
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return [self.navigationController.viewControllers containsObject:_lastMenuViewController];

    return YES;
}

- (void) closeMenuAndPanelsAnimated:(BOOL)animated
{
    // This fixes issue with stuck toolbar
    self.navigationController.toolbarHidden = YES;

    // Close all menus and panels
    [self closeMenuAnimated:animated];
    [self showCenterPanelAnimated:animated];
    
    /*
    if (self.state == JASidePanelLeftVisible)
        [self toggleLeftPanel:self];
    else if (self.state == JASidePanelRightVisible)
        [self toggleRightPanel:self];
     */
}

- (void) sqliteDbImportedAlert
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"import_title") message:@"Map Creator file has been imported. Open Map Settings and activate it via Overlay/Underlay" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

- (void) sqliteDbImportFailedAlert
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"import_title") message:@"Map Creator file import failed" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

- (void) installSqliteDbFile:(NSString *)path newFileName:(NSString *)newFileName
{
    if ([[OAMapCreatorHelper sharedInstance] installFile:path newFileName:newFileName])
        [self sqliteDbImportedAlert];
    else
        [self sqliteDbImportFailedAlert];
}

- (BOOL) handleIncomingURL:(NSURL *)url
{
    NSString *path = url.path;
    NSString *fileName = [url.path lastPathComponent];
    NSString *ext = [[path pathExtension] lowercaseString];
    
    if ([ext isEqualToString:@"sqlitedb"])
    {
        NSString *newFileName = [[OAMapCreatorHelper sharedInstance] getNewNameIfExists:fileName];
        if (newFileName)
        {
            [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"sqlitedb_import_title") message:OALocalizedString(@"sqlitedb_import_already_exists")
                cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")
                                    action:^{
                                    }]
                otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"fav_replace")
                                    action:^{
                                        [self installSqliteDbFile:path newFileName:nil];
                                    }],
                                 [RIButtonItem itemWithLabel:OALocalizedString(@"gpx_add_new")
                                    action:^{
                                        [self installSqliteDbFile:path newFileName:newFileName];
                                    }],
                nil] show];
        }
        else
        {
            [self installSqliteDbFile:path newFileName:nil];
        }
        
        [self.navigationController popToRootViewControllerAnimated:NO];

        return YES;
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"import_title")
                                    message:OALocalizedString(@"import_choose_type")
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")
                                                                 action:^{
                                                                 }]
                           otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"import_favorite")
                                                                 action:^{
                                                                     
                                                                     UIViewController* incomingURLViewController = [[OAFavoriteImportViewController alloc] initFor:url];
                                                                     if (incomingURLViewController == nil)
                                                                         return;
                                                                     
                                                                     if (((OAFavoriteImportViewController *)incomingURLViewController).handled == NO)
                                                                     {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             
                                                                             [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"import_failed") message:OALocalizedString(@"import_cannot") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
                                                                             
                                                                         });
                                                                         
                                                                         incomingURLViewController = nil;
                                                                         return;
                                                                     }
                                                                     
                                                                     [self closeMenuAndPanelsAnimated:NO];
                                                                     
                                                                     [self.navigationController pushViewController:incomingURLViewController
                                                                                                          animated:YES];
                                                                     // Open incoming-URL view controller as menu
                                                                     /*
                                                                     [self openMenu:incomingURLViewController
                                                                           fromRect:CGRectZero
                                                                             inView:self.view
                                                                           ofParent:self
                                                                           animated:YES];
                                                                      */
                                                                     
                                                                 }],
          
          [RIButtonItem itemWithLabel:OALocalizedString(@"import_gpx")
                               action:^{
                                   
                                   UIViewController* incomingURLViewController = [[OAGPXListViewController alloc] initWithImportGPXItem:url];
                                   if (incomingURLViewController == nil)
                                       return;
                                   
                                   [self closeMenuAndPanelsAnimated:NO];
                                   
                                   [self.navigationController pushViewController:incomingURLViewController
                                                                        animated:YES];
                                   // Open incoming-URL view controller as menu
                                   /*
                                   [self openMenu:incomingURLViewController
                                         fromRect:CGRectZero
                                           inView:self.view
                                         ofParent:self
                                         animated:YES];
                                    */
                                   
                               }],
          
          nil] show];
        
        return YES;
    }
}

- (void) showNoInternetAlert
{
    [self showNoInternetAlertFor:nil];
}

- (void) showNoInternetAlertFor:(NSString*)actionTitle
{
    [[[UIAlertView alloc] initWithTitle:actionTitle
                                message:OALocalizedString(@"alert_inet_needed")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_ok")]
                       otherButtonItems:nil] show];
}

- (MBProgressHUD *) showProgress:(EOAProgressType)progressType
{
    UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
    MBProgressHUD *currentProgress;
    MBProgressHUD *newProgress = [[MBProgressHUD alloc] initWithView:topView];
    switch (progressType)
    {
        case EOARequestProductsProgressType:
            currentProgress = _requestProgressHUD;
            _requestProgressHUD = newProgress;
            break;
        case EOAPurchaseProductProgressType:
            currentProgress = _purchaseProgressHUD;
            _purchaseProgressHUD = newProgress;
            break;
        case EOARestorePurchasesProgressType:
            currentProgress = _restoreProgressHUD;
            _restoreProgressHUD = nil;
            break;
        default:
            break;
    }
    if (currentProgress && currentProgress.superview)
        [currentProgress hide:YES];

    newProgress.minShowTime = .5f;
    newProgress.removeFromSuperViewOnHide = YES;
    [topView addSubview:newProgress];
    [newProgress show:YES];
    
    return newProgress;
}

- (void) hideProgress:(EOAProgressType)progressType
{
    MBProgressHUD *progress;
    switch (progressType)
    {
        case EOARequestProductsProgressType:
            progress = _requestProgressHUD;
            _requestProgressHUD = nil;
            break;
        case EOAPurchaseProductProgressType:
            progress = _purchaseProgressHUD;
            _purchaseProgressHUD = nil;
            break;
        case EOARestorePurchasesProgressType:
            progress = _restoreProgressHUD;
            _restoreProgressHUD = nil;
            break;
        default:
            break;
    }
    if (progress && progress.superview)
        [progress hide:YES];
}

- (BOOL) requestProductsWithProgress:(BOOL)showProgress reload:(BOOL)reload
{
    if (![_iapHelper productsLoaded] || reload)
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        {
            if (showProgress)
                [self showProgress:EOARequestProductsProgressType];
            
            _productsRequestNeeded = NO;
            _productsRequestReload = NO;
            _productsRequestWithProgress = NO;
            [_iapHelper requestProductsWithCompletionHandler:^(BOOL success)
             {
                 if (success)
                     [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductsRequestSucceedNotification object:nil userInfo:nil];
                 else
                     [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductsRequestFailedNotification object:nil userInfo:nil];

                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (showProgress)
                         [self hideProgress:EOARequestProductsProgressType];
                 });
             }];
            return YES;
        }
        else
        {
            _productsRequestNeeded = YES;
            _productsRequestReload = reload;
            _productsRequestWithProgress = showProgress;
            return NO;
        }
    }
    return YES;
}

- (BOOL) buyProduct:(OAProduct *)product showProgress:(BOOL)showProgress
{
    if (![product isPurchased])
    {
        _restoringPurchases = NO;
        if (showProgress)
            [self showProgress:EOAPurchaseProductProgressType];

        [_iapHelper buyProduct:product];
        return YES;
    }
    return NO;
}

- (BOOL) restorePurchasesWithProgress:(BOOL)showProgress
{
    if (![_iapHelper productsLoaded])
        return NO;

    _restoringPurchases = YES;
    if (showProgress)
        [self showProgress:EOARestorePurchasesProgressType];

    [_iapHelper restoreCompletedTransactions];
    return YES;
}

- (void) requestPurchase:(NSNotification *)notification
{
    SKPayment *payment = notification.object;
    if (![_iapHelper productsLoaded])
    {
        [_iapHelper requestProductsWithCompletionHandler:^(BOOL success) {
            if (success)
                [self requestingPurchase:payment];
        }];
    }
    else
    {
        [self requestingPurchase:payment];
    }
}

- (void) requestingPurchase:(SKPayment *)payment
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_iapHelper.liveUpdates getPurchasedSubscription])
        {
            [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"already_has_subscription") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
        }
        else
        {
            OAProduct *p = [_iapHelper product:payment.productIdentifier];
            if (p)
            {
                if ([p isPurchased])
                {
                    NSString *text = [NSString stringWithFormat:OALocalizedString(@"already_has_inapp"), p.localizedTitle];
                    [[[UIAlertView alloc] initWithTitle:@"" message:text delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
                }
                else
                {
                    [OAChoosePlanHelper showChoosePlanScreenWithProduct:p navController:self.navigationController purchasing:YES];
                    // todo
                    [[SKPaymentQueue defaultQueue] addPayment:payment];
                }
            }
            else
            {
                NSString *text = [NSString stringWithFormat:OALocalizedString(@"inapp_not_found"), p.localizedTitle];
                [[[UIAlertView alloc] initWithTitle:@"" message:text delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            }
        }
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideProgress:EOAPurchaseProductProgressType];
        
        NSString * identifier = notification.object;
        OAProduct *product = nil;
        if (identifier)
            product = [_iapHelper product:identifier];
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if (product && [product isKindOfClass:[OASubscription class]] && ((OASubscription* )product).donationSupported && settings.displayDonationSettings)
        {
            settings.displayDonationSettings = NO;
            OADonationSettingsViewController *donationController = [[OADonationSettingsViewController alloc] init];
            [self.navigationController pushViewController:donationController animated:YES];
        }
    });
}

- (void) productPurchaseDeferred:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgress:EOAPurchaseProductProgressType];
    });
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    if (_restoringPurchases)
        return;
    
    NSString * identifier = notification.object;
    OAProduct *product = nil;
    if (identifier)
        product = [_iapHelper product:identifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideProgress:EOAPurchaseProductProgressType];
        
        if (product)
        {
            NSString *title = [NSString stringWithFormat:OALocalizedString(@"prch_failed"), product.localizedTitle];
            NSString *text = notification.userInfo ? notification.userInfo[@"error"] : nil;
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:text delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (void) productsRestored:(NSNotification *)notification
{
    NSNumber *errorsCountObj = notification.object;
    int errorsCount = errorsCountObj.intValue;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideProgress:EOARestorePurchasesProgressType];

        if (errorsCount > 0)
        {
            NSString *text = [NSString stringWithFormat:@"%d %@", errorsCount, OALocalizedString(@"prch_items_failed")];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
    
}

- (void) reachabilityChanged:(NSNotification *)notification
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        if (_productsRequestNeeded)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestProductsWithProgress:_productsRequestWithProgress reload:_productsRequestReload];
            });
        }
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (_lastMenuPopoverController == popoverController)
    {
        if ([_lastMenuOriginViewController conformsToProtocol:@protocol(OAMenuOriginViewControllerProtocol)])
        {
            id<OAMenuOriginViewControllerProtocol> origin = (id<OAMenuOriginViewControllerProtocol>)_lastMenuOriginViewController;
            [origin notifyMenuClosed];
        }

        _lastMenuOriginViewController = nil;
        _lastMenuPopoverController = nil;
    }
}

@end
