//
//  OAIAPHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIAPHelper.h"
#import "OALog.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import <Reachability.h>
#import "OAAnalyticsHelper.h"
#import "OANetworkUtilities.h"
#import "OADonationSettingsViewController.h"
#import <CommonCrypto/CommonDigest.h>

NSString *const OAIAPProductsRequestSucceedNotification = @"OAIAPProductsRequestSucceedNotification";
NSString *const OAIAPProductsRequestFailedNotification = @"OAIAPProductsRequestFailedNotification";
NSString *const OAIAPProductPurchasedNotification = @"OAIAPProductPurchasedNotification";
NSString *const OAIAPProductPurchaseFailedNotification = @"OAIAPProductPurchaseFailedNotification";
NSString *const OAIAPProductPurchaseDeferredNotification = @"OAIAPProductPurchaseDeferredNotification";
NSString *const OAIAPProductsRestoredNotification = @"OAIAPProductsRestoredNotification";
NSString *const OAIAPRequestPurchaseProductNotification = @"OAIAPRequestPurchaseProductNotification";

#define TEST_LOCAL_PURCHASE NO

#define kAllSubscriptionsExpiredStatus 100
#define kNoSubscriptionsFoundStatus 110
#define kInconsistentReceiptStatus 200
#define kUserNotFoundStatus 300

typedef void (^RequestActiveProductsCompletionHandler)(NSArray<OAProduct *> *products, NSDictionary<NSString *, NSDate *> *expirationDates, BOOL success);

@interface OAIAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic) BOOL subscribedToLiveUpdates;

@end

@implementation OAIAPHelper
{
    OAAppSettings *_settings;
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    
    RequestActiveProductsCompletionHandler _activeProductsCompletionHandler;
    SKReceiptRefreshRequest *_receiptRequest;
    
    OAProducts *_products;

    BOOL _restoringPurchases;
    NSInteger _transactionErrors;
    
    BOOL _wasAddedToQueue;
    BOOL _wasProductListFetched;
}

+ (int) freeMapsAvailable
{
    int freeMaps = kFreeMapsAvailableTotal;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"freeMapsAvailable"]) {
        freeMaps = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"freeMapsAvailable"];
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:kFreeMapsAvailableTotal forKey:@"freeMapsAvailable"];
    }

    OALog(@"Free maps available: %d", freeMaps);
    return freeMaps;
}

+ (void) decreaseFreeMapsCount
{
    int freeMaps = kFreeMapsAvailableTotal;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"freeMapsAvailable"]) {
        freeMaps = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"freeMapsAvailable"];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:--freeMaps forKey:@"freeMapsAvailable"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    OALog(@"Free maps left: %d", freeMaps);
}

+ (void) increaseFreeMapsCount:(int)count
{
    int freeMaps = kFreeMapsAvailableTotal;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"freeMapsAvailable"]) {
        freeMaps = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"freeMapsAvailable"];
    }
    freeMaps += count;
    [[NSUserDefaults standardUserDefaults] setInteger:freeMaps forKey:@"freeMapsAvailable"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    OALog(@"Free maps left: %d", freeMaps);
}

+ (OAIAPHelper *) sharedInstance
{
    static dispatch_once_t once;
    static OAIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (OAProduct *) skiMap
{
    return _products.skiMap;
}

- (OAProduct *) nautical
{
    return _products.nautical;
}

- (OAProduct *) trackRecording
{
    return _products.trackRecording;
}

- (OAProduct *) osmEditing
{
    return _products.osmEditing;
}

- (OAProduct *) mapillary
{
    return _products.mapillary;
}

- (OAProduct *) openPlaceReviews
{
    return _products.openPlaceReviews;
}

- (OAProduct *) parking
{
    return _products.parking;
}

- (OAProduct *) wiki
{
    return _products.wiki;
}

- (OAProduct *) srtm
{
    return _products.srtm;
}

- (OAProduct *) weather
{
    return _products.weather;
}

- (OAProduct *) allWorld
{
    return _products.allWorld;
}

- (OAProduct *) russia
{
    return _products.russia;
}

- (OAProduct *) antarctica
{
    return _products.antarctica;
}

- (OAProduct *) africa
{
    return _products.africa;
}

- (OAProduct *) asia
{
    return _products.asia;
}

- (OAProduct *) australia
{
    return _products.australia;
}

- (OAProduct *) europe
{
    return _products.europe;
}

- (OAProduct *) centralAmerica
{
    return _products.centralAmerica;
}

- (OAProduct *) northAmerica
{
    return _products.northAmerica;
}

- (OAProduct *) southAmerica
{
    return _products.southAmerica;
}

- (NSArray<OAFunctionalAddon *> *) functionalAddons
{
    return _products.functionalAddons;
}

- (OAFunctionalAddon *) singleAddon
{
    return _products.singleAddon;
}

- (OASubscription *) monthlyLiveUpdates
{
    return _products.monthlyLiveUpdates;
}

- (OASubscriptionList *) liveUpdates
{
    return _products.liveUpdates;
}

- (NSArray<OAProduct *> *) inApps
{
    return _products.inApps;
}

- (NSArray<OAProduct *> *) inAppMaps
{
    return _products.inAppMaps;
}

- (NSArray<OAProduct *> *) inAppAddons
{
    return _products.inAppAddons;
}

- (NSArray<OAProduct *> *) inAppsFree
{
    return _products.inAppsFree;
}

- (NSArray<OAProduct *> *) inAppsPaid
{
    return _products.inAppsPaid;
}

- (NSArray<OAProduct *> *)inAppAddonsPaid
{
    return _products.inAppAddonsPaid;
}

- (NSArray<OAProduct *> *) inAppPurchased
{
    return _products.inAppsPurchased;
}

- (NSArray<OAProduct *> *) inAppAddonsPurchased
{
    return _products.inAppAddonsPurchased;
}

- (BOOL) productsLoaded
{
    return _wasProductListFetched;
}

- (OAProduct *) product:(NSString *)productIdentifier
{
    return [_products getProduct:productIdentifier];
}

- (instancetype) init
{
    if ((self = [super init]))
    {
        _settings = [OAAppSettings sharedManager];
        _products = [[OAProducts alloc] init];
        _wasProductListFetched = NO;
        
        // test - reset osm live purchases
        if (TEST_LOCAL_PURCHASE)
        {
            [_settings.liveUpdatesPurchased set:NO];
            for (OASubscription *s in [_products.liveUpdates getAllSubscriptions])
                [_products setExpired:s.productIdentifier];
        }
    }
    return self;
}

- (void) requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler
{
    // Add self as transaction observer
    if (!_wasAddedToQueue)
    {
        _wasAddedToQueue = YES;
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }

    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/api/subscriptions/active" params:@{ @"os" : @"ios", @"version" : ver } post:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        if (response && data)
        {
            @try
            {
                NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                if (map)
                {
                    NSArray *names = map.allKeys;
                    for (NSString *subscriptionType in names)
                    {
                        id subObj = [map objectForKey:subscriptionType];
                        NSString *identifier = [subObj objectForKey:@"sku"];                        
                        if (identifier.length > 0)
                            [self.liveUpdates upgradeSubscription:identifier];
                    }
                }
                
                _completionHandler = [completionHandler copy];
                _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[OAProducts getProductIdentifiers:_products.inAppsPaid]];
                _productsRequest.delegate = self;
                [_productsRequest start];
            }
            @catch (NSException *e)
            {
                if (completionHandler)
                    completionHandler(NO);
            }
        }
        else
        {
            if (completionHandler)
                completionHandler(NO);
        }
    }];
}

- (void) disableProduct:(NSString *)productIdentifier
{
    OAProduct *product = [self product:productIdentifier];
    if (product)
        [_products disableProduct:product];
}

- (void) enableProduct:(NSString *)productIdentifier
{
    OAProduct *product = [self product:productIdentifier];
    if (product)
        [_products enableProduct:product];
}

- (void) buyProduct:(OAProduct *)product
{
    OALog(@"Buying %@...", product.productIdentifier);
    
    // test - emulate purchasing
    if (TEST_LOCAL_PURCHASE)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self provideContentForProductIdentifier:product.productIdentifier transaction:nil];
        });
        return;
    }
    
    [self logTransactionType:@"buy" productIdentifier:product.productIdentifier];
    if ([product isKindOfClass:[OASubscription class]])
        [self buySubscription:(OASubscription *)product];
    else
        [self buyInApp:product];
}

- (void) buyInApp:(OAProduct *)product
{
    _restoringPurchases = NO;
    
    if ([self productsLoaded] && product.skProduct)
    {
        SKPayment * payment = [SKPayment paymentWithProduct:product.skProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else
    {
        OAIAPHelper * __weak weakSelf = self;
        _completionHandler = ^(BOOL success) {
            if (!success)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:product.productIdentifier userInfo:@{@"error" : [NSString stringWithFormat:@"buyInApp: Cannot request product: %@", product.productIdentifier]}];
            }
            else
            {
                OAProduct *p = [weakSelf product:product.productIdentifier];
                if (p)
                    [weakSelf buyProduct:p];
            }
        };
        
        NSSet *s = [[NSSet alloc] initWithObjects:product.productIdentifier, nil];
        _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:s];
        _productsRequest.delegate = self;
        [_productsRequest start];
    }
}

- (void) buySubscription:(OASubscription *)subscription
{
    _restoringPurchases = NO;
    
    if ([self productsLoaded] && subscription.skProduct)
    {
        NSString *userId = _settings.billingUserId.get;
        if (!userId || userId.length == 0)
        {
            NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
            [params setObject:@"ios" forKey:@"os"];
            NSString *visibleName = _settings.billingHideUserName.get ? @"" : _settings.billingUserName.get;
            if (visibleName)
                [params setObject:visibleName forKey:@"visibleName"];

            NSString *preferredCountry = _settings.billingUserCountryDownloadName.get;
            if (preferredCountry)
                [params setObject:preferredCountry forKey:@"preferredCountry"];

            NSString *email = _settings.billingUserEmail.get;
            if (email)
                [params setObject:email forKey:@"email"];

            [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/register" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
             {
                 NSString *errorStr = error ? error.localizedDescription : nil;
                 if (!error && response && data)
                 {
                     @try
                     {
                         NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                         if (map)
                         {
                             NSString *userId = [map objectForKey:@"userid"];
                             NSLog(@"UserId = %@", userId);
                             if (userId.length > 0)
                             {
                                 [self applyUserPreferences:map];
                                 _settings.displayDonationSettings = subscription.donationSupported;
                                 [self launchPurchase:subscription];
                             }
                             else
                             {
                                 errorStr = @"No userId";
                             }
                         }
                     }
                     @catch (NSException *e)
                     {
                         errorStr = [NSString stringWithFormat:@"%@: %@", e.name, e.reason];
                     }
                 }
                 else
                 {
                     if (!errorStr || [errorStr length] == 0)
                         errorStr = @"unknown error";
                 }
                 if (errorStr)
                     [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:subscription.productIdentifier userInfo:@{@"error" : [NSString stringWithFormat:@"/register %@", errorStr]}];
             }];
        }
        else
        {
            _settings.displayDonationSettings = subscription.donationSupported;
            [self launchPurchase:subscription];
        }
    }
    else
    {
        OAIAPHelper * __weak weakSelf = self;
        _completionHandler = ^(BOOL success) {
            if (!success)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:subscription.productIdentifier userInfo:@{@"error" : [NSString stringWithFormat:@"buySubscription: Cannot request product: %@", subscription.productIdentifier]}];
            }
            else
            {
                OAProduct *p = [weakSelf product:subscription.productIdentifier];
                if (p && [p isKindOfClass:[OASubscription class]])
                    [weakSelf buySubscription:(OASubscription *)p];
            }
        };
        
        NSSet *s = [[NSSet alloc] initWithObjects:subscription.productIdentifier, nil];
        _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:s];
        _productsRequest.delegate = self;
        [_productsRequest start];
    }
}

- (void) launchPurchase:(OASubscription *)subscription
{
    NSLog(@"Launching purchase flow for live updates subscription");
    if (@available(iOS 12.2, *))
    {
        OAPaymentDiscount *paymentDiscount = nil;
        if (_settings.eligibleForSubscriptionOffer && subscription.discounts.count > 0)
        {
            for (OAProductDiscount *discount in subscription.discounts)
                if (discount.paymentDiscount)
                {
                    paymentDiscount = discount.paymentDiscount;
                    break;
                }
        }
        if (paymentDiscount)
        {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:subscription.skProduct];
            payment.applicationUsername = paymentDiscount.username;
            SKPaymentDiscount *discountOffer = [[SKPaymentDiscount alloc] initWithIdentifier:paymentDiscount.identifier keyIdentifier:paymentDiscount.keyIdentifier nonce:paymentDiscount.nonce signature:paymentDiscount.signature timestamp:paymentDiscount.timestamp];
            payment.paymentDiscount = discountOffer;
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
        else
        {
            SKPayment *payment = [SKPayment paymentWithProduct:subscription.skProduct];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }
    else
    {
        SKPayment *payment = [SKPayment paymentWithProduct:subscription.skProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (BOOL) subscribedToLiveUpdates
{
#ifdef DEBUG
    return YES;
#else
    return _settings.liveUpdatesPurchased.get;
#endif
}

- (OASubscription *) getCheapestMonthlySubscription
{
    NSArray<OASubscription *> *subscriptions = [self.liveUpdates getVisibleSubscriptions];
    OASubscription *cheapest = nil;
    for (OASubscription *subscription in subscriptions)
    {
        if (!cheapest || subscription.monthlyPrice.doubleValue < cheapest.monthlyPrice.doubleValue)
            cheapest = subscription;
    }
    return cheapest;
}

- (BOOL) isAnyMapPurchased
{
    for (OAProduct *map in self.inAppMaps)
        if ([map isPurchased])
            return YES;
    
    return NO;
}

#pragma mark - SKProductsRequestDelegate

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    OALog(@"Loaded list of products...");
    _productsRequest = nil;
    
    for (SKProduct * skProduct in response.products)
    {
        if (skProduct)
        {
            OALog(@"Found product: %@ %@ %0.2f",
                  skProduct.productIdentifier,
                  skProduct.localizedTitle,
                  skProduct.price.floatValue);
            [_products updateProduct:skProduct];
        }
    }
    
    [self getActiveProducts:^(NSArray<OAProduct *> *products, NSDictionary<NSString *,NSDate *> *expirationDates, BOOL success) {
        
        if (products)
        {
            [expirationDates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull prodId, NSDate * _Nonnull expDate, BOOL * _Nonnull stop) {
                [_products setExpirationDate:prodId expirationDate:expDate];
            }];
            
            for (OAProduct *product in self.inAppAddonsPaid)
            {
                // Need to be sure that inapp will not be expired by mistake. Then uncomment lines.
                //if (![products containsObject:product])
                //    [_products setExpired:product.productIdentifier];
            }
            
            NSMutableArray<OAProduct *> *purchased = [NSMutableArray array];
            BOOL subscribedToLiveUpdates = NO;
            for (OAProduct *product in products)
            {
                BOOL isSubscription = [product isKindOfClass:[OASubscription class]];
                if (!subscribedToLiveUpdates && isSubscription)
                    subscribedToLiveUpdates = YES;
                
                BOOL wasPurchased = [product isPurchased];
                [_products setPurchased:product.productIdentifier];
                if (!wasPurchased)
                    [purchased addObject:product];
            }
            
            NSTimeInterval subscriptionCancelledTime = _settings.liveUpdatesPurchaseCancelledTime.get;
            if (!subscribedToLiveUpdates && self.subscribedToLiveUpdates)
            {
                OASubscription *s = [self.liveUpdates getPurchasedSubscription];
                if (s)
                    [_products setExpired:s.productIdentifier];

                if (subscriptionCancelledTime == 0)
                {
                    subscriptionCancelledTime = [[[NSDate alloc] init] timeIntervalSince1970];
                    [_settings.liveUpdatesPurchaseCancelledTime set:subscriptionCancelledTime];
                    [_settings.liveUpdatesPurchaseCancelledFirstDlgShown set:NO];
                    [_settings.liveUpdatesPurchaseCancelledSecondDlgShown set:NO];
                }
                else if ([[[NSDate alloc] init] timeIntervalSince1970] - subscriptionCancelledTime > kSubscriptionHoldingTimeMsec)
                {
                    [_settings.liveUpdatesPurchased set:NO];
                    //if (!isDepthContoursPurchased(ctx))
                    //    ctx.getSettings().getCustomRenderBooleanProperty("depthContours").set(false);
                }
            }
            else if (subscribedToLiveUpdates)
            {
                [_settings.liveUpdatesPurchaseCancelledTime set:0];
                [_settings.liveUpdatesPurchased set:YES];
            }
            
            for (OAProduct *p in purchased)
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:p.productIdentifier userInfo:nil];
        }
        
        _wasProductListFetched = success;

        if (_completionHandler)
            _completionHandler(success);
        
        _completionHandler = nil;
    }];
}

- (void) requestDidFinish:(SKRequest *)request
{
    if (request == _productsRequest)
    {
        OALog(@"Products request did finish OK");
    }
    else if (request == _receiptRequest)
    {
        OALog(@"Receipt request did finish OK");
        _receiptRequest = nil;
        [self getActiveProducts:_activeProductsCompletionHandler];
    }
    else
    {
        OALog(@"SKRequest did finish OK");
    }
}

- (void) request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSString *requestName;
    if (request == _productsRequest)
        requestName = @"Products";
    else if (request == _receiptRequest)
        requestName = @"Receipt";
    else
        requestName = @"Unknown";

    OALog(@"%@ request did fail with error: %@", requestName, error.localizedDescription);
    
    if (request == _productsRequest)
    {
        _productsRequest = nil;
        
        if (_completionHandler)
            _completionHandler(NO);
        
        _completionHandler = nil;
    }
    else if (request == _receiptRequest)
    {
        _receiptRequest = nil;
        
        if (_activeProductsCompletionHandler)
            _activeProductsCompletionHandler(nil, nil, NO);
        
        _activeProductsCompletionHandler = nil;
    }
}

#pragma mark SKPaymentTransactionObserver

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                _transactionErrors++;
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            case SKPaymentTransactionStateDeferred:
                [self deferredTransaction:transaction];
            default:
                break;
        }
    };
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductsRestoredNotification object:[NSNumber numberWithInteger:_transactionErrors] userInfo:nil];
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductsRestoredNotification object:[NSNumber numberWithInteger:_transactionErrors] userInfo:nil];
}

// Sent when a user initiates an IAP buy from the App Store
- (BOOL) paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPRequestPurchaseProductNotification object:payment userInfo:nil];
    return NO;
}

- (void) completeTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction)
    {
        if (transaction.payment && transaction.payment.productIdentifier)
        {
            if (![self productsLoaded])
            {
                OALog(@"Cannot completeTransaction - %@. Products are not loaded yet.", transaction.payment.productIdentifier);
            }
            else
            {
                OALog(@"completeTransaction - %@", transaction.payment.productIdentifier);
                [self logTransactionType:@"purchased" productIdentifier:transaction.payment.productIdentifier];
                [self provideContentForProductIdentifier:transaction.payment.productIdentifier transaction:transaction.originalTransaction ? transaction.originalTransaction : transaction];
            }
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

- (void) restoreTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction)
    {
        if (transaction.originalTransaction && transaction.originalTransaction.payment && transaction.originalTransaction.payment.productIdentifier)
        {
            if (![self productsLoaded])
            {
                OALog(@"Cannot restoreTransaction - %@. Products are not loaded yet.", transaction.originalTransaction.payment.productIdentifier);
            }
            else
            {
                OALog(@"restoreTransaction - %@", transaction.originalTransaction.payment.productIdentifier);
                [self logTransactionType:@"restored" productIdentifier:transaction.originalTransaction.payment.productIdentifier];
                [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier transaction:transaction.originalTransaction];
            }
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

- (void) deferredTransaction:(SKPaymentTransaction *)transaction
{
    OALog(@"Transaction deferred state: %@", transaction.payment.productIdentifier);
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseDeferredNotification object:transaction.payment.productIdentifier userInfo:nil];
}

- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction)
    {
        if (transaction.payment && transaction.payment.productIdentifier)
        {
            NSString *productIdentifier = transaction.payment.productIdentifier;
            OALog(@"failedTransaction - %@", productIdentifier);
            [self logTransactionType:@"failed" productIdentifier:productIdentifier];
            if (transaction.error && transaction.error.code != SKErrorPaymentCancelled)
            {
                OALog(@"Transaction error: %@", transaction.error.localizedDescription);
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:productIdentifier userInfo:@{@"error" : [NSString stringWithFormat:@"failedTransaction %@ - %@", productIdentifier, transaction.error.localizedDescription]}];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:nil userInfo:@{@"error" : [NSString stringWithFormat:@"failedTransaction %@ - %@", productIdentifier, transaction.error ? transaction.error.localizedDescription : @"Unknown error"]}];
            }
        }
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
}

- (void) logTransactionType:(NSString *)transactionType productIdentifier:(NSString *)productIdentifier
{
    NSString *truncatedIdentifier = [self truncateIdentifier:productIdentifier];
    [OAAnalyticsHelper logEvent:[NSString stringWithFormat:@"%@_%@", transactionType, truncatedIdentifier]];
}

- (NSString *) truncateIdentifier:(NSString *)identifier
{
    NSArray<NSString *> *items = [identifier componentsSeparatedByString:@"."];
    NSUInteger count = items.count;
    if (count > 3)
        return [NSString stringWithFormat:@"%@_%@_%@", items[count - 3], items[count - 2], items[count - 1]];
    
    return [identifier stringByReplacingOccurrencesOfString:@"." withString:@"_"];
}

- (void) applyUserPreferences:(NSDictionary *)map
{
    NSObject *userId = [map objectForKey:@"userid"];
    if (userId)
        [_settings.billingUserId set:[userId isKindOfClass:[NSString class]] ? (NSString *)userId : @""];

    NSObject *token = [map objectForKey:@"token"];
    if (token)
        [_settings.billingUserToken set:[token isKindOfClass:[NSString class]] ? (NSString *)token : @""];

    NSObject *visibleName = [map objectForKey:@"visibleName"];
    if (visibleName && [visibleName isKindOfClass:[NSString class]] && ((NSString *)visibleName).length > 0)
    {
        [_settings.billingUserName set:(NSString *)visibleName];
        [_settings.billingHideUserName set:NO];
    }
    else
    {
        [_settings.billingHideUserName set:YES];
    }
    NSObject *preferredCountryObj = [map objectForKey:@"preferredCountry"];
    if (preferredCountryObj && [preferredCountryObj isKindOfClass:[NSString class]])
    {
        NSString *preferredCountry = (NSString *)preferredCountryObj;
        if (![_settings.billingUserCountryDownloadName.get isEqualToString:preferredCountry])
        {
            [_settings.billingUserCountryDownloadName set:preferredCountry];
            OADonationSettingsViewController *donationSettingsController = [[OADonationSettingsViewController alloc] init];
            [donationSettingsController initCountries];
            NSArray<OACountryItem *> *countryItems = donationSettingsController.countryItems;
            OACountryItem *countryItem = nil;
            if (preferredCountry.length == 0)
                countryItem = countryItems[0];
            else if (![preferredCountry isEqualToString:kBillingUserDonationNone])
                countryItem = [donationSettingsController getCountryItem:preferredCountry];
            
            if (countryItem)
                [_settings.billingUserCountry set:countryItem.localName];
        }
    }
    NSObject *email = [map objectForKey:@"email"];
    if (email)
        [_settings.billingUserEmail set:[email isKindOfClass:[NSString class]] ? (NSString *)email : @""];
}

- (void) provideContentForProductIdentifier:(NSString * _Nonnull)productIdentifier transaction:(SKPaymentTransaction *)transaction
{
    OAProduct *product = [self product:productIdentifier];
    if (product)
    {
        if ([product isKindOfClass:[OASubscription class]])
        {
            NSLog(@"Live updates subscription purchased.");
            
            // test - emulate purchase
            if (TEST_LOCAL_PURCHASE)
            {
                [_settings.liveUpdatesPurchased set:YES];
                [_products setPurchased:productIdentifier];
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];
                return;
            }
            
            NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
            NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
            if (!receipt || !transaction)
            {
                NSLog(@"Error: No local receipt or transaction");
                NSMutableString *errorText = [NSMutableString string];
                if (!receipt)
                    [errorText appendString:@" (no receipt)"];
                if (!transaction)
                    [errorText appendString:@" (no transation)"];

                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:productIdentifier userInfo:@{@"error" : [NSString stringWithFormat:@"provideContent:%@ -%@", productIdentifier, errorText]}];
            }
            else
            {
                NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
                [params setObject:@"ios" forKey:@"os"];
                NSString *userId = _settings.billingUserId.get;
                if (userId)
                    [params setObject:userId forKey:@"userid"];
                
                NSString *token = _settings.billingUserToken.get;
                if (token)
                    [params setObject:token forKey:@"token"];

                NSString *sku = productIdentifier;
                if (sku)
                    [params setObject:sku forKey:@"sku"];
                
                NSString *transactionId = transaction.transactionIdentifier;
                if (transactionId)
                    [params setObject:transactionId forKey:@"purchaseToken"];

                NSString *receiptStr = [receipt base64EncodedStringWithOptions:0];
                if (receiptStr)
                    [params setObject:receiptStr forKey:@"payload"];

                NSString *email = _settings.billingUserEmail.get;
                if (email)
                    [params setObject:email forKey:@"email"];
                
                [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/purchased" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                 {
                     NSString *errorStr = error ? error.localizedDescription : nil;
                     if (!error && response && data)
                     {
                         @try
                         {
                             NSLog([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                             NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                             if (map)
                             {
                                 if (![map objectForKey:@"error"])
                                 {
                                     if ([map objectForKey:@"userid"])
                                         [self applyUserPreferences:map];

                                     [_settings.liveUpdatesPurchased set:YES];
                                     _settings.lastReceiptValidationDate = [NSDate dateWithTimeIntervalSince1970:0];
                                     [_products setPurchased:productIdentifier];
                                     [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];
                                 }
                                 else
                                 {
                                     errorStr = [NSString stringWithFormat:@"Purchase subscription failed: %@ (userId=%@ response=%@)", [map objectForKey:@"error"], _settings.billingUserId.get, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                                     NSLog(errorStr);
                                 }
                             }
                         }
                         @catch (NSException *e)
                         {
                             errorStr = [NSString stringWithFormat:@"%@: %@", e.name, e.reason];
                         }
                     }
                     else
                     {
                         if (!errorStr || [errorStr length] == 0)
                             errorStr = @"unknown error";
                     }
                     if (errorStr)
                         [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:product.productIdentifier userInfo:@{@"error" : [NSString stringWithFormat:@"/purchased %@", errorStr]}];
                 }];
            }
        }
        else
        {
            [_products setPurchased:productIdentifier];
            [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];
        }
    }
}

- (void) restoreCompletedTransactions
{
    _settings.lastReceiptValidationDate = [NSDate dateWithTimeIntervalSince1970:0];
    _restoringPurchases = YES;
    _transactionErrors = 0;
    
#ifdef DEBUG
    [_settings.liveUpdatesPurchased set:![_settings.liveUpdatesPurchased get]];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
#else
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
#endif
}

- (BOOL) needValidateReceipt
{
    if (!_settings.billingUserId.get)
        return YES;
    
    NSTimeInterval lastReceiptValidationTimeInterval = [[[NSDate alloc] init] timeIntervalSinceDate:_settings.lastReceiptValidationDate];
    OASubscription *subscription = [_products.liveUpdates getPurchasedSubscription];
    if (subscription)
    {
        NSDate *expDate = subscription.expirationDate;
        if (!expDate)
            return YES;
        
        if ([[[NSDate alloc] init] timeIntervalSinceDate:expDate] > 0 && lastReceiptValidationTimeInterval > kReceiptValidationMinPeriod)
            return YES;
        
        return NO;
    }
    return lastReceiptValidationTimeInterval > kReceiptValidationMaxPeriod;
}

- (void) getActiveProducts:(RequestActiveProductsCompletionHandler)onComplete
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    
#if TARGET_OS_SIMULATOR
    if (onComplete)
        onComplete(nil, nil, YES);
    
    return;
#endif
    
    if (!receipt)
    {
        NSLog(@"No local receipt. Requesting new one...");
        _activeProductsCompletionHandler = onComplete;
        _receiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
        _receiptRequest.delegate = self;
        [_receiptRequest start];
    }
    else if ([self needValidateReceipt])
    {
        NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
        [params setObject:@"ios" forKey:@"os"];
        NSString *userId = _settings.billingUserId.get;
        if (userId)
            [params setObject:userId forKey:@"userid"];
        
        NSString *receiptStr = [receipt base64EncodedStringWithOptions:0];
        [params setObject:receiptStr forKey:@"receipt"];
        [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/ios-receipt-validate" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
         {
             BOOL success = NO;
             NSMutableArray<OAProduct *> *products = nil;
             NSMutableDictionary<NSString *, NSDate *> *expirationDates = nil;
             if (response && data)
             {
                 @try
                 {
                     NSLog([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                     NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                     if (map)
                     {
                         if (![map objectForKey:@"error"] && [map objectForKey:@"status"])
                         {
                             int status = [[map objectForKey:@"status"] intValue];
                             if (status == 0 || status == kAllSubscriptionsExpiredStatus)
                             {
                                 success = YES;
                                 _settings.lastReceiptValidationDate = [[NSDate alloc] init];
                                 if ([map objectForKey:@"eligible_for_introductory_price"])
                                     _settings.eligibleForIntroductoryPrice = [[map objectForKey:@"eligible_for_introductory_price"] boolValue];
                                 if ([map objectForKey:@"eligible_for_subscription_offer"])
                                     _settings.eligibleForSubscriptionOffer = [[map objectForKey:@"eligible_for_subscription_offer"] boolValue];

                                 products = [NSMutableArray array];
                                 expirationDates = [NSMutableDictionary dictionary];
                                 NSDictionary *userData = [map objectForKey:@"user"];
                                 if (userData)
                                     [self applyUserPreferences:userData];
                                 
                                 NSArray *inApps = [map objectForKey:@"in_apps"];
                                 for (NSString *inAppId in inApps)
                                 {
                                     OAProduct *product = [self product:inAppId];
                                     if (product)
                                         [products addObject:product];
                                 }
                                 
                                 NSArray *subscriptions = [map objectForKey:@"subscriptions"];
                                 for (NSDictionary *subscription in subscriptions)
                                 {
                                     NSString *subscriptionId = subscription[@"product_id"];
                                     if (subscriptionId)
                                     {
                                         OAProduct *product = [self product:subscriptionId];
                                         if (product)
                                             [products addObject:product];
                                         
                                         NSString *expirationDate = subscription[@"expiration_date"];
                                         if (expirationDate)
                                         {
                                             long long expDateMs = [expirationDate longLongValue];
                                             if (expDateMs > 0 && expDateMs < LLONG_MAX)
                                             {
                                                 NSDate* expDate = [NSDate dateWithTimeIntervalSince1970:[expirationDate longLongValue] / 1000.0];
                                                 [expirationDates setObject:expDate forKey:subscriptionId];
                                             }
                                         }
                                     }
                                 }
                             }
                             else if (status == kUserNotFoundStatus || status == kNoSubscriptionsFoundStatus)
                             {
                                 success = YES;
                                 _settings.eligibleForIntroductoryPrice = YES;
                                 _settings.eligibleForSubscriptionOffer = NO;
                                 _settings.lastReceiptValidationDate = [[NSDate alloc] init];
                             }
                         }
                     }
                 }
                 @catch (NSException *e)
                 {
                     products = nil;
                 }
             }
             if (@available(iOS 12.2, *))
             {
                 [self fetchSubscriptionOfferSignatures:^{
                     if (onComplete)
                         onComplete(products, expirationDates, success);
                 }];
             }
             else if (onComplete)
             {
                 onComplete(products, expirationDates, success);
             }
         }];
    }
    else
    {
        if (@available(iOS 12.2, *))
        {
            [self fetchSubscriptionOfferSignatures:^{
                if (onComplete)
                    onComplete(nil, nil, YES);
            }];
        }
        else if (onComplete)
        {
            onComplete(nil, nil, YES);
        }
    }
}

- (void) fetchSubscriptionOfferSignatures:(void (^)(void))onComplete API_AVAILABLE(ios(12.2))
{
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    [params setObject:@"ios" forKey:@"os"];
    NSString *userId = _settings.billingUserId.get;
    if (userId)
        [params setObject:userId forKey:@"userId"];

    NSMutableSet<NSString *> *productIdentifiers = [NSMutableSet set];
    NSArray<OASubscription *> *subscriptions = [_products.liveUpdates getVisibleSubscriptions];
    for (OASubscription *s in subscriptions)
        if (s.discounts)
        {
            NSMutableString *discountIdentifiersStr = [NSMutableString string];
            for (OAProductDiscount *d in s.discounts)
            {
                if (discountIdentifiersStr.length > 0)
                    [discountIdentifiersStr appendString:@";"];
                
                [discountIdentifiersStr appendString:d.identifier];
            }
            if (discountIdentifiersStr.length > 0)
            {
                [params setObject:discountIdentifiersStr forKey:[NSString stringWithFormat:@"%@_discounts", s.productIdentifier]];
                [productIdentifiers addObject:s.productIdentifier];
            }
        }

    if (productIdentifiers.count > 0)
    {
        NSMutableString *productIdentifiersStr = [NSMutableString string];
        for (NSString *productIdentifier in productIdentifiers)
        {
            if (productIdentifiersStr.length > 0)
                [productIdentifiersStr appendString:@";"];
            
            [productIdentifiersStr appendString:productIdentifier];
        }
        [params setObject:productIdentifiersStr forKey:@"productIdentifiers"];
        
        [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/ios-fetch-signatures" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
         {
             BOOL success = NO;
             if (response && data)
             {
                 @try
                 {
                     NSLog([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                     NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                     if (map)
                     {
                         if (![map objectForKey:@"error"] && [map objectForKey:@"status"])
                         {
                             int status = [[map objectForKey:@"status"] intValue];
                             if (status == 0)
                             {
                                 success = YES;
                                 NSMutableArray<OAPaymentDiscount *> *paymentDiscounts = [NSMutableArray array];
                                 NSArray *signatures = [map objectForKey:@"signatures"];
                                 for (NSDictionary *signature in signatures)
                                 {
                                     NSString *keyIdentifier = signature[@"keyIdentifier"];
                                     NSString *productIdentifier = signature[@"productIdentifier"];
                                     NSString *offerIdentifier = signature[@"offerIdentifier"];
                                     NSString *usernameHash = signature[@"usernameHash"];
                                     NSString *nonce = signature[@"nonce"];
                                     NSString *timestamp = signature[@"timestamp"];
                                     NSString *s = signature[@"signature"];
                                     OAPaymentDiscount *paymentDiscount = [[OAPaymentDiscount alloc] initWithIdentifier:offerIdentifier productIdentifier:productIdentifier username:usernameHash keyIdentifier:keyIdentifier nonce:[[NSUUID alloc] initWithUUIDString:nonce] signature:s timestamp:@(timestamp.longLongValue)];
                                     [paymentDiscounts addObject:paymentDiscount];
                                 }
                                 for (OAPaymentDiscount *paymentDiscount in paymentDiscounts)
                                 {
                                     OASubscription *subscription = [_products.liveUpdates getSubscriptionByIdentifier:paymentDiscount.productIdentifier];
                                     if (subscription)
                                     {
                                         for (OAProductDiscount *discount in subscription.discounts)
                                         {
                                             if ([discount.identifier isEqualToString:paymentDiscount.identifier])
                                                 discount.paymentDiscount = paymentDiscount;
                                         }
                                     }
                                 }
                             }
                         }
                     }
                 }
                 @catch (NSException *e)
                 {
                 }
             }
             if (onComplete)
                 onComplete();
         }];
    }
    else
    {
        if (onComplete)
            onComplete();
    }
}

@end
