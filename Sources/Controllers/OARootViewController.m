//
//  OARootViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OARootViewController.h"
#import <SafariServices/SafariServices.h>
#import <MBProgressHUD.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OAAppDelegate.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAMenuOriginViewControllerProtocol.h"
#import "OAMenuViewControllerProtocol.h"
#import "OAFavoriteImportViewController.h"
#import "OAOptionsPanelBlackViewController.h"
#import "OAApplicationMode.h"
#import "OAMapCreatorHelper.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OADonationSettingsViewController.h"
#import "OAChoosePlanHelper.h"
#import "OAFileImportHelper.h"
#import "OASettingsHelper.h"
#import "OAXmlImportHandler.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OABackupHelper.h"
#import "OACloudAccountVerificationViewController.h"
#import "SceneDelegate.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OANavigationController.h"
#import "OsmAnd_Maps-Swift.h"

#define _(name) OARootViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define TEST_LOCAL_PURCHASE NO

typedef enum : NSUInteger {
    EOARequestProductsProgressType,
    EOAPurchaseProductProgressType,
    EOARestorePurchasesProgressType
} EOAProgressType;

@interface OARootViewController () <UIPopoverControllerDelegate, SFSafariViewControllerDelegate>
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

    BOOL _isSearchScreenOpened;
    BOOL _isNavigationScreenOpened;
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
    _keyCommandUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onKeyCommandUpdate:withKey:)];

    // Create panels:
    [self setLeftPanel:[[OAOptionsPanelBlackViewController alloc] initWithNibName:@"OptionsPanel" bundle:nil]];
    [self setCenterPanel:[[OAMapPanelViewController alloc] init]];
    //[self setRightPanel:[[OAActionsPanelViewController alloc] init]];
}

+ (OARootViewController*) instance
{
    OAAppDelegate *appDelegate = (OAAppDelegate *)[[UIApplication sharedApplication] delegate];
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseDeferred:) name:OAIAPProductPurchaseDeferredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestPurchase:) name:OAIAPRequestPurchaseProductNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.token != nil)
    {
        [self handleOsmAndCloudVerification:self.token];
        self.token = nil;
    }
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

- (void)updateLeftPanelMenu
{
    OAOptionsPanelBlackViewController *controller = (OAOptionsPanelBlackViewController *)self.leftPanel;
    if ([controller respondsToSelector:@selector(updateMenu)])
       [controller updateMenu];
}

- (void) handleOsmAndCloudVerification:(NSString *)tokenParam
{
    OACloudAccountVerificationViewController *verificationVC = [[OACloudAccountVerificationViewController alloc] initWithEmail:OAAppSettings.sharedManager.backupUserEmail.get sourceType:EOACloudScreenSourceTypeSignIn];
    [self.navigationController pushViewController:verificationVC animated:NO];
    
    if ([OABackupHelper isTokenValid:tokenParam])
    {
        [OABackupHelper.sharedInstance registerDevice:tokenParam];
    }
    else
    {
        verificationVC.errorMessage = OALocalizedString(@"backup_error_invalid_token");
        [verificationVC updateScreen];
    }
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
    if ([OAUtilities isIPhone])
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
    [self.class showInfoAlertWithTitle:OALocalizedString(@"import_title")
                               message:OALocalizedString(@"import_raster_map_success")
                          inController:self];
}

- (void) sqliteDbImportFailedAlert
{
    [self.class showInfoAlertWithTitle:OALocalizedString(@"import_title")
                               message:OALocalizedString(@"import_raster_map_failed")
                          inController:self];
}

- (void) installSqliteDbFile:(NSString *)path newFileName:(NSString *)newFileName
{
    if ([[OAMapCreatorHelper sharedInstance] installFile:path newFileName:newFileName])
        [self sqliteDbImportedAlert];
    else
        [self sqliteDbImportFailedAlert];
}

- (void) importObfFile:(NSString *)path newFileName:(NSString *)newFileName
{
    BOOL imported = [[OAFileImportHelper sharedInstance] importObfFileFromPath:path newFileName:newFileName];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:imported ? OALocalizedString(@"obf_import_success") : OALocalizedString(@"obf_import_failed") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)importAsFavorites:(NSURL *)url
{
    OAFavoriteImportViewController *favoriteImportViewController = [[OAFavoriteImportViewController alloc] initFor:url];

    if (favoriteImportViewController.handled == NO)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.class showInfoAlertWithTitle:OALocalizedString(@"import_failed")
                                       message:OALocalizedString(@"import_cannot")
                                  inController:self];
        });
        favoriteImportViewController = nil;
    }

    [self closeMenuAndPanelsAnimated:NO];

    if (favoriteImportViewController)
    {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:favoriteImportViewController];
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)importAsGPX:(NSURL *)url
{
    [self importAsGPX:url showAlerts:YES openGpxView:YES];
}

- (void)importAsGPX:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView
{
    OAGPXImportUIHelper *importHelper = [[OAGPXImportUIHelper alloc] initWithHostViewController:self];
    [importHelper prepareProcessUrl:url showAlerts:showAlerts openGpxView:openGpxView completion:nil];
    [self closeMenuAndPanelsAnimated:NO];
}

+ (void)showInfoAlertWithTitle:(NSString *)title
                       message:(NSString *)message
                  inController:(UIViewController *)controller
{
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction
                                actionWithTitle:OALocalizedString(@"shared_string_ok")
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [controller presentViewController:alert animated:YES completion:nil];
}

- (BOOL) handleIncomingURL:(NSURL *)url_
{
    NSURL *url = url_;

    NSString *path = url.path;
    NSString *fileName = [url.path lastPathComponent];

    if ([fileName hasSuffix:@".wpt.chart"] || [fileName hasSuffix:@".3d.chart"])
    {
        NSString *newFileName = [fileName stringByReplacingOccurrencesOfString:@".wpt.chart" withString:@".gpx"];
        newFileName = [newFileName stringByReplacingOccurrencesOfString:@".3d.chart" withString:@".sqlitedb"];
        NSString *newPath = [NSTemporaryDirectory() stringByAppendingString:newFileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:newPath])
            [[NSFileManager defaultManager] removeItemAtPath:newPath error:nil];

        if ([path containsString:[OsmAndApp instance].inboxPath])
            [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:nil];
        else
            [[NSFileManager defaultManager] copyItemAtPath:path toPath:newPath error:nil];

        url = [NSURL fileURLWithPath:newPath];
    }

    path = url.path;
    fileName = [url.path lastPathComponent];
    NSString *ext = [[path pathExtension] lowercaseString];

    if (![OAUtilities getAccessToFile:path])
    {
        [self.class showInfoAlertWithTitle:OALocalizedString(@"import_failed")
                                   message:OALocalizedString(@"import_cannot")
                              inController:self];
        return NO;
    }

    [[self mapPanel] onHandleIncomingURL:ext];

    if ([ext isEqualToString:@"sqlitedb"])
    {
        NSString *newFileName = [[OAMapCreatorHelper sharedInstance] getNewNameIfExists:fileName];
        if (newFileName)
        {
            UIAlertController *alert = [UIAlertController
                                            alertControllerWithTitle:OALocalizedString(@"sqlitedb_import_title")
                                            message:OALocalizedString(@"sqlitedb_import_already_exists")
                                            preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *cancelButtonItem = [UIAlertAction
                                            actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                            style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [OAUtilities denyAccessToFile:path removeFromInbox:YES];
            }];

            UIAlertAction *replaceButtonItem = [UIAlertAction
                                            actionWithTitle:OALocalizedString(@"update_existing")
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                    [self installSqliteDbFile:path newFileName:nil];
                                }];

            UIAlertAction *addNewButtonItem = [UIAlertAction
                                            actionWithTitle:OALocalizedString(@"gpx_add_new")
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                    [self installSqliteDbFile:path newFileName:newFileName];
                                }];

            [alert addAction:replaceButtonItem];
            [alert addAction:addNewButtonItem];
            [alert addAction:cancelButtonItem];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self installSqliteDbFile:path newFileName:nil];
        }
        
        [self.navigationController popToRootViewControllerAnimated:NO];

        return YES;
    }
    else if ([ext isEqualToString:@"obf"])
    {
        NSString *newFileName = [[OAFileImportHelper sharedInstance] getNewNameIfExists:fileName];
        if (newFileName)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"obf_import_title") message:OALocalizedString(@"obf_import_already_exists") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [OAUtilities denyAccessToFile:path removeFromInbox:YES];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"update_existing") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self importObfFile:path newFileName:nil];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"gpx_add_new") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self importObfFile:path newFileName:newFileName];
            }]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self importObfFile:path newFileName:nil];
        }
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        return YES;
    }
    else if ([ext caseInsensitiveCompare:@"xml"] == NSOrderedSame)
    {
        OAXmlImportHandler *xmlHandler = [[OAXmlImportHandler alloc] initWithUrl:url];
        [xmlHandler handleImport];
    }
    else if ([ext caseInsensitiveCompare:@"gpx"] == NSOrderedSame)
    {
        if (([fileName.lowerCase hasPrefix:@"favourites"] || [fileName.lowerCase hasPrefix:@"favorites"]) && [fileName.pathExtension.lowerCase isEqualToString:@"gpx"])
            [self importAsFavorites:url];
        else
            [self importAsGPX:url];
    }
    else if ([ext caseInsensitiveCompare:@"kml"] == NSOrderedSame || [ext caseInsensitiveCompare:@"kmz"] == NSOrderedSame)
    {
        [self importAsGPX:url];
    }
    else if ([ext caseInsensitiveCompare:@"osf"] == NSOrderedSame)
    {
        OASettingsHelper *helper = OASettingsHelper.sharedInstance;
        [helper collectSettings:url.path latestChanges:@"" version:kVersion];
    }
    
    return YES;
}

- (void) showNoInternetAlert
{
    [self showNoInternetAlertFor:nil];
}

- (void) showNoInternetAlertFor:(NSString*)actionTitle
{
    [self.class showInfoAlertWithTitle:actionTitle message:OALocalizedString(@"alert_inet_needed") inController:self];
}

- (MBProgressHUD *) showProgress:(EOAProgressType)progressType
{
    UIView *topView = [UIApplication sharedApplication].mainWindow;
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

- (BOOL) requestProductsWithProgress:(BOOL)showProgress reload:(BOOL)reload restorePurchases:(BOOL)restore
{
    if (TEST_LOCAL_PURCHASE && restore)
        return [self restorePurchasesWithProgress:NO];

    if (![_iapHelper productsLoaded] || reload)
    {
        if (AFNetworkReachabilityManager.sharedManager.isReachable)
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
                     if (restore)
                         [self restorePurchasesWithProgress:NO];
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

- (BOOL) requestProductsWithProgress:(BOOL)showProgress reload:(BOOL)reload
{
    return [self requestProductsWithProgress:showProgress reload:reload restorePurchases:NO];
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
    if (TEST_LOCAL_PURCHASE)
    {
        [_iapHelper buyProduct:_iapHelper.proAnnually];
        [_iapHelper buyProduct:[_iapHelper.subscriptionList getSubscriptionByIdentifier:[kSubscriptionId_Osm_Live_Subscription_3_Months stringByAppendingString:@"_v1"]]];
        [_iapHelper buyProduct:_iapHelper.mapsFull];
        [_iapHelper buyProduct:_iapHelper.allWorld];
        [_iapHelper buyProduct:_iapHelper.europe];
        [_iapHelper buyProduct:_iapHelper.nautical];
        [_iapHelper buyProduct:_iapHelper.srtm];
        [_iapHelper buyProduct:_iapHelper.wiki];
        [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductsRestoredNotification object:nil userInfo:nil];
        return YES;
    }

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
        OAProduct *p = [_iapHelper product:payment.productIdentifier];
        if (p && [p isKindOfClass:OASubscription.class] && [[_iapHelper.subscriptionList getPurchasedSubscriptions] containsObject:(OASubscription *)p])
        {
            [self.class showInfoAlertWithTitle:@"" message:OALocalizedString(@"already_has_subscription") inController:self];
        }
        else
        {
            if (p)
            {
                if ([p isPurchased])
                {
                    NSString *text = [NSString stringWithFormat:OALocalizedString(@"already_has_inapp"), p.localizedTitle];
                    
                    [self.class showInfoAlertWithTitle:@"" message:text inController:self];
                }
                else
                {
                    [OAChoosePlanHelper showChoosePlanScreenWithProduct:p navController:self.navigationController];
                    // todo
                    [[SKPaymentQueue defaultQueue] addPayment:payment];
                }
            }
            else
            {
                NSString *text = [NSString stringWithFormat:OALocalizedString(@"inapp_not_found"), p.localizedTitle];
                
                [self.class showInfoAlertWithTitle:@"" message:text inController:self];
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
            [self.class showInfoAlertWithTitle:title message:text inController:self];
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
            
            [self.class showInfoAlertWithTitle:@"" message:text inController:self];
        }
    });
    
}

- (void) reachabilityChanged:(NSNotification *)notification
{
    if (AFNetworkReachabilityManager.sharedManager.isReachable)
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

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void)onKeyCommandUpdate:(id<OAObservableProtocol>)observer withKey:(id)key
{
    if ([key isKindOfClass:NSString.class])
    {
        NSString *kKey = (NSString *) key;
        if ([kKey isEqualToString:kCommandSearchScreenOpen])
            _isSearchScreenOpened = YES;
        else if ([kKey isEqualToString:kCommandSearchScreenClose])
            _isSearchScreenOpened = NO;
        else if ([kKey isEqualToString:kCommandNavigationScreenOpen])
            _isNavigationScreenOpened = YES;
        else if ([kKey isEqualToString:kCommandNavigationScreenClose])
            _isNavigationScreenOpened = NO;
    }
}

- (NSArray<UIKeyCommand *> *)keyCommands
{
    NSArray<UIKeyCommand *> *commands = @[
        [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(panDown)],
        [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(panUp)],
        [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(panLeft)],
        [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(panRight)],
        [UIKeyCommand keyCommandWithInput:@"-" modifierFlags:0 action:@selector(zoomOut)],
        [UIKeyCommand keyCommandWithInput:@"+" modifierFlags:0 action:@selector(zoomIn)],
        [UIKeyCommand keyCommandWithInput:@"=" modifierFlags:0 action:@selector(zoomIn)],
        [UIKeyCommand keyCommandWithInput:@"-" modifierFlags:UIKeyModifierCommand action:@selector(zoomOut)],
        [UIKeyCommand keyCommandWithInput:@"+" modifierFlags:UIKeyModifierCommand action:@selector(zoomIn)],
        [UIKeyCommand keyCommandWithInput:@"=" modifierFlags:UIKeyModifierCommand action:@selector(zoomIn)],
        [UIKeyCommand keyCommandWithInput:@"0" modifierFlags:UIKeyModifierCommand action:@selector(recenterMap)],
        [UIKeyCommand keyCommandWithInput:@"c" modifierFlags:0 action:@selector(recenterMap)],
        [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:0 action:@selector(changeMapOrienation)],
        [UIKeyCommand keyCommandWithInput:@"n" modifierFlags:0 action:@selector(showRouteInfo)],
        [UIKeyCommand keyCommandWithInput:@"o" modifierFlags:0 action:@selector(changeAppModeToPrev)],
        [UIKeyCommand keyCommandWithInput:@"p" modifierFlags:0 action:@selector(changeAppModeToNext)],
        [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:0 action:@selector(openSearch)]
    ];
    for (UIKeyCommand *command in commands)
    {
        command.wantsPriorityOverSystemBehavior = YES;
    }
    return commands;
}

- (void) changeMapOrienation
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [[OAMapViewTrackingUtilities instance] switchRotateMapMode];
}

- (void) showRouteInfo
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
    {
        if (!_isNavigationScreenOpened)
            [self.mapPanel showRouteInfo];
    }
}

- (void) openSearch
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
    {
        if (!_isSearchScreenOpened && !_isNavigationScreenOpened)
            [self.mapPanel openSearch];
    }
}

- (void) panUp
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == WUNDERLINQ_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController zoomIn];
    else if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController animatedPanUp];
}

- (void) panDown
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == WUNDERLINQ_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController zoomOut];
    else if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController animatedPanDown];
}

- (void) panLeft
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController animatedPanLeft];
}

- (void) panRight
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController animatedPanRight];
}

- (void) zoomOut
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
    {
        [self.mapPanel.mapViewController zoomOut];
        [self.mapPanel.mapViewController calculateMapRuler];
    }
}

- (void) zoomIn
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [self.mapPanel.mapViewController zoomIn];
}

- (void) recenterMap
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
        [[OAMapViewTrackingUtilities instance] backToLocationImpl];
}

- (void)changeAppModeToNext
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
    {
        OAApplicationMode *selectedMode = [[OAAppSettings sharedManager].applicationMode get];
        NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
        NSInteger selectedModeIndex = [availableModes indexOfObject:selectedMode];
        if (availableModes.count - 1 > selectedModeIndex)
            [[OAAppSettings sharedManager] setApplicationModePref:availableModes[selectedModeIndex + 1]];
        else
            [[OAAppSettings sharedManager] setApplicationModePref:availableModes.firstObject];

        NSString *profileName = selectedMode.name.length > 0 ? selectedMode.name : [selectedMode getUserProfileName];
        [OAUtilities showToast:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"),
                                                          OALocalizedString(@"shared_string_app_profile"),
                                                          [[[OAAppSettings sharedManager].applicationMode get] toHumanString]]
                       details:nil
                      duration:4
                        inView:self.view];
    }
}

- (void)changeAppModeToPrev
{
    if ([[OAAppSettings sharedManager].settingExternalInputDevice get] == GENERIC_EXTERNAL_DEVICE)
    {
        OAApplicationMode *selectedMode = [[OAAppSettings sharedManager].applicationMode get];
        NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
        NSInteger selectedModeIndex = [availableModes indexOfObject:selectedMode];
        if (selectedModeIndex == 0)
            [[OAAppSettings sharedManager] setApplicationModePref:availableModes.lastObject];
        else
            [[OAAppSettings sharedManager] setApplicationModePref:availableModes[selectedModeIndex - 1]];

        [OAUtilities showToast:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"),
                                                          OALocalizedString(@"shared_string_app_profile"),
                                                          [[[OAAppSettings sharedManager].applicationMode get] toHumanString]]
                       details:nil
                      duration:4
                        inView:self.view];
    }
}

#pragma mark SFSafariViewControllerDelegate

- (void)openSafariWithURL:(NSString *)url
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    safariViewController.delegate = self;
    [self.navigationController pushViewController:safariViewController animated:YES];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark JASidePanelController

- (void)_addPanGestureToView:(UIView *)view {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePan:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    panGesture.name = kLeftPannelGestureRecognizer;
    [view addGestureRecognizer:panGesture];
}

@end
