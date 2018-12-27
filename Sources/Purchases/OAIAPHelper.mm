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
#import "OAFirebaseHelper.h"
#import "OANetworkUtilities.h"

NSString *const OAIAPProductPurchasedNotification = @"OAIAPProductPurchasedNotification";
NSString *const OAIAPProductPurchaseFailedNotification = @"OAIAPProductPurchaseFailedNotification";
NSString *const OAIAPProductsRestoredNotification = @"OAIAPProductsRestoredNotification";


@interface OAIAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic) BOOL subscribedToLiveUpdates;

@end

@implementation OAIAPHelper
{
    OAAppSettings *_settings;
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    
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

- (OAProduct *) tripPlanning
{
    return _products.tripPlanning;
}

- (OAProduct *) allWorld
{
    return _products.allWorld;
}

- (OAProduct *) russia
{
    return _products.russia;
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
        if (response)
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
                // ignore
            }
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
    if ([product isKindOfClass:[OASubscription class]])
    {
        [OAFirebaseHelper logEvent:[@"subsciption_buy_" stringByAppendingString:product.productIdentifier]];
        [self buySubscription:(OASubscription *)product];
    }
    else
    {
        [OAFirebaseHelper logEvent:[@"inapp_buy_" stringByAppendingString:product.productIdentifier]];
        [self buyInApp:product];
    }
}

- (void) buyInApp:(OAProduct *)product
{
    _restoringPurchases = NO;
    
    if (product.skProduct)
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
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:nil userInfo:nil];
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
    
    if (subscription.skProduct)
    {
        NSString *userId = _settings.billingUserId;
        if (userId.length == 0)
        {
            NSDictionary<NSString *, NSString *> *params = @{
                                                             @"os" : @"ios",
                                                             @"visibleName" : _settings.billingHideUserName ? @"" : _settings.billingUserName,
                                                             @"preferredCountry" : _settings.billingUserCountryDownloadName,
                                                             @"email" : _settings.billingUserEmail
                                                             };
            [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/register" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
             {
                 if (response)
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
                                 _settings.billingUserId = userId;
                                 NSLog(@"Launching purchase flow for live updates subscription");
                                 
                                 SKPayment * payment = [SKPayment paymentWithProduct:subscription.skProduct];
                                 [[SKPaymentQueue defaultQueue] addPayment:payment];
                             }
                         }
                     }
                     @catch (NSException *e)
                     {
                         // ignore
                     }
                 }
             }];
        }
    }
    else
    {
        OAIAPHelper * __weak weakSelf = self;
        _completionHandler = ^(BOOL success) {
            if (!success)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:nil userInfo:nil];
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

- (BOOL) subscribedToLiveUpdates
{
    if (!_subscribedToLiveUpdates)
        _subscribedToLiveUpdates = [self.liveUpdates getPurchasedSubscription] != nil;

    return _subscribedToLiveUpdates;
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
    
    if (_completionHandler)
        _completionHandler(YES);
    
    _completionHandler = nil;
    
    _wasProductListFetched = YES;
}

- (void) request:(SKRequest *)request didFailWithError:(NSError *)error{
    
    OALog(@"Failed to load list of products.");
    _productsRequest = nil;
    
    if (_completionHandler)
        _completionHandler(NO);
    
    _completionHandler = nil;
    
}

#pragma mark SKPaymentTransactionOBserver

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

- (void) completeTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction)
    {
        if (transaction.payment && transaction.payment.productIdentifier)
        {
            OALog(@"completeTransaction - %@", transaction.payment.productIdentifier);
            
            OAProduct *product = [self product:transaction.payment.productIdentifier];
            if (product && [self.inAppMaps containsObject:product])
                _isAnyMapPurchased = YES;
            
            if ([product isKindOfClass:[OASubscription class]])
                [OAFirebaseHelper logEvent:[@"subscription_purchased_" stringByAppendingString:transaction.payment.productIdentifier]];
            else
                [OAFirebaseHelper logEvent:[@"inapp_purchased_" stringByAppendingString:transaction.payment.productIdentifier]];

            [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
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
            OALog(@"restoreTransaction - %@", transaction.originalTransaction.payment.productIdentifier);
            
            OAProduct *product = [self product:transaction.originalTransaction.payment.productIdentifier];
            if (product && [self.inAppMaps containsObject:product])
                _isAnyMapPurchased = YES;
            
            if ([product isKindOfClass:[OASubscription class]])
                [OAFirebaseHelper logEvent:[@"subscription_restored_" stringByAppendingString:transaction.originalTransaction.payment.productIdentifier]];
            else
                [OAFirebaseHelper logEvent:[@"inapp_restored_" stringByAppendingString:transaction.originalTransaction.payment.productIdentifier]];

            [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction)
    {
        if (transaction.payment && transaction.payment.productIdentifier)
        {
            OAProduct *product = [self product:transaction.payment.productIdentifier];
            OALog(@"failedTransaction - %@", transaction.payment.productIdentifier);
            if ([product isKindOfClass:[OASubscription class]])
                [OAFirebaseHelper logEvent:[@"subscription_failed_" stringByAppendingString:transaction.payment.productIdentifier]];
            else
                [OAFirebaseHelper logEvent:[@"inapp_failed_" stringByAppendingString:transaction.payment.productIdentifier]];
            
            if (transaction.error && transaction.error.code != SKErrorPaymentCancelled)
            {
                OALog(@"Transaction error: %@", transaction.error.localizedDescription);
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:transaction.payment.productIdentifier userInfo:nil];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:nil userInfo:nil];
            }
        }
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
}

- (void) provideContentForProductIdentifier:(NSString * _Nonnull)productIdentifier
{
    OAProduct *product = [self product:productIdentifier];
    if (product)
    {
        if ([product isKindOfClass:[OASubscription class]])
        {
            NSLog(@"Live updates subscription purchased.");
            
            NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
            NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
            if (!receipt)
            {
                NSLog(@"Error: No local receipt");
            }
            else
            {
                NSDictionary<NSString *, NSString *> *params = @{
                                                                 @"os" : @"ios",
                                                                 @"userid" : _settings.billingUserId,
                                                                 @"sku" : productIdentifier,
                                                                 @"purchaseToken" : [receipt base64EncodedStringWithOptions:0],
                                                                 @"email" : _settings.billingUserEmail
                                                                 };
                [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/purchased" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                 {
                     if (response)
                     {
                         @try
                         {
                             NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                             if (map)
                             {
                                 if (![map objectForKey:@"error"])
                                 {
                                     NSString *visibleName = [map objectForKey:@"visibleName"];
                                     if (visibleName.length > 0)
                                     {
                                         _settings.billingUserName = visibleName;
                                         _settings.billingHideUserName = NO;
                                     }
                                     else
                                     {
                                         _settings.billingHideUserName = YES;
                                     }
                                     NSString *preferredCountry = [map objectForKey:@"preferredCountry"];
                                     if (preferredCountry)
                                     {
                                         if (![_settings.billingUserCountryDownloadName isEqualToString:preferredCountry])
                                         {
                                             _settings.billingUserCountryDownloadName = preferredCountry;
                                             /* todo
                                             CountrySelectionFragment countrySelectionFragment = new CountrySelectionFragment();
                                             countrySelectionFragment.initCountries(ctx);
                                             CountryItem countryItem = null;
                                             if (Algorithms.isEmpty(prefferedCountry)) {
                                                 countryItem = countrySelectionFragment.getCountryItems().get(0);
                                             } else if (!prefferedCountry.equals(OsmandSettings.BILLING_USER_DONATION_NONE_PARAMETER)) {
                                                 countryItem = countrySelectionFragment.getCountryItem(prefferedCountry);
                                             }
                                             if (countryItem != null) {
                                                 _settings.billingUserCountry;
                                                 ctx.getSettings().BILLING_USER_COUNTRY.set(countryItem.getLocalName());
                                             }
                                              */
                                         }
                                     }
                                     NSString *email = [map objectForKey:@"email"];
                                     if (email)
                                         _settings.billingUserEmail = email;

                                     [_products setPurchased:productIdentifier];
                                 }
                                 else
                                 {
                                     NSLog(@"Purchase subscription failed: %@ (userId=%@ response=%@)", [map objectForKey:@"error"], _settings.billingUserId, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                 }
                             }
                         }
                         @catch (NSException *e)
                         {
                             // ignore
                         }
                     }
                 }];
            }
        }
        else
        {
            [_products setPurchased:productIdentifier];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];
}

- (void) restoreCompletedTransactions
{
    _restoringPurchases = YES;
    _transactionErrors = 0;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end
