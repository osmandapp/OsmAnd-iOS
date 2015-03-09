//
//  OAIAPHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIAPHelper.h"
#import "OALog.h"

NSString *const OAIAPProductPurchasedNotification = @"OAIAPProductPurchasedNotification";
NSString *const OAIAPProductPurchaseFailedNotification = @"OAIAPProductPurchaseFailedNotification";

@interface OAIAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation OAIAPHelper {
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
    
    NSArray *_skProducts;

}

+ (OAIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static OAIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      kInAppId_Region_Africa,
                                      kInAppId_Region_Russia,
                                      kInAppId_Region_Asia,
                                      kInAppId_Region_Australia,
                                      kInAppId_Region_Europe,
                                      kInAppId_Region_Central_America,
                                      kInAppId_Region_North_America,
                                      kInAppId_Region_South_America,
                                      kInAppId_Addon_SkiMap,
                                      kInAppId_Addon_Nautical,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

+(NSArray *)inAppsMaps
{
    return [NSArray arrayWithObjects:
            kInAppId_Region_Africa,
            kInAppId_Region_Russia,
            kInAppId_Region_Asia,
            kInAppId_Region_Australia,
            kInAppId_Region_Europe,
            kInAppId_Region_Central_America,
            kInAppId_Region_North_America,
            kInAppId_Region_South_America,
            nil];
}

+(NSArray *)inAppsAddons
{
    return [NSArray arrayWithObjects:
            kInAppId_Addon_SkiMap,
            kInAppId_Addon_Nautical,
            nil];
}

-(BOOL)productsLoaded
{
    return _skProducts.count > 0;
}

-(SKProduct *)product:(NSString *)productIdentifier
{
    for (SKProduct *p in _skProducts) {
        if ([p.productIdentifier isEqualToString:productIdentifier])
            return p;
    }
    return nil;
}

-(int)productIndex:(NSString *)productIdentifier
{
    NSArray *maps = [self.class inAppsMaps];
    for (int i = 0; i < maps.count; i++)
        if ([maps[i] isEqualToString:productIdentifier])
            return i;
    
    NSArray *addons = [self.class inAppsAddons];
    for (int i = 0; i < addons.count; i++)
        if ([addons[i] isEqualToString:productIdentifier])
            return i;

    return -1;
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                OALog(@"Previously purchased: %@", productIdentifier);
            } else {
                OALog(@"Not purchased: %@", productIdentifier);
            }
        }
        
        // Add self as transaction observer
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
    }
    return self;
    
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    _completionHandler = [completionHandler copy];
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProduct:(SKProduct *)product {
    
    OALog(@"Buying %@...", product.productIdentifier);
    
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    OALog(@"Loaded list of products...");
    _productsRequest = nil;
    
    _skProducts = response.products;
    for (SKProduct * skProduct in _skProducts) {
        OALog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES);
    _completionHandler = nil;
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    OALog(@"Failed to load list of products.");
    _productsRequest = nil;
    
    _completionHandler(NO);
    _completionHandler = nil;
    
}

#pragma mark SKPaymentTransactionOBserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    OALog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    OALog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    OALog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        OALog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:transaction.originalTransaction.payment.productIdentifier userInfo:nil];

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];
    
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end