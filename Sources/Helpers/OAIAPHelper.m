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

NSString *const OAIAPProductPurchasedNotification = @"OAIAPProductPurchasedNotification";
NSString *const OAIAPProductPurchaseFailedNotification = @"OAIAPProductPurchaseFailedNotification";
NSString *const OAIAPProductsRestoredNotification = @"OAIAPProductsRestoredNotification";


@implementation OAFunctionalAddon

-(instancetype)initWithAddonId:(NSString *)addonId titleShort:(NSString *)titleShort titleWide:(NSString *)titleWide imageName:(NSString *)imageName
{
    self = [super init];
    if (self)
    {
        _addonId = [addonId copy];
        _titleShort = [titleShort copy];
        _titleWide = [titleWide copy];
        _imageName = [imageName copy];
    }
    return self;
}

@end


@interface OAIAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation OAIAPHelper
{
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
    NSMutableSet * _disabledProductIdentifiers;
    
    NSArray *_skProducts;

    BOOL _restoringPurchases;
    NSInteger _transactionErrors;
}

+(int)freeMapsAvailable
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

+(void)decreaseFreeMapsCount
{
    int freeMaps = kFreeMapsAvailableTotal;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"freeMapsAvailable"]) {
        freeMaps = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"freeMapsAvailable"];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:--freeMaps forKey:@"freeMapsAvailable"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    OALog(@"Free maps left: %d", freeMaps);

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
                                      kInAppId_Region_All_World,
                                      kInAppId_Addon_SkiMap,
                                      kInAppId_Addon_Nautical,
                                      kInAppId_Addon_TrackRecording,
                                      kInAppId_Addon_Parking,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

+(NSArray *)inAppsMaps
{
    return [NSArray arrayWithObjects:
            kInAppId_Region_All_World,
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
            kInAppId_Addon_TrackRecording,
            kInAppId_Addon_Parking,
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

- (NSString *) getDisabledId:(NSString *)productIdentifier
{
    return [productIdentifier stringByAppendingString:@"_disabled"];
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        _purchasedProductIdentifiers = [NSMutableSet set];
        _disabledProductIdentifiers = [NSMutableSet set];
        
        // Check for previously purchased products
        for (NSString * productIdentifier in _productIdentifiers) {
#if !defined(OSMAND_IOS_DEV)
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
#else
            BOOL productPurchased = YES;
#endif            
            if (productPurchased) {
                
                BOOL productDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:[self getDisabledId:productIdentifier]];
                if (productDisabled)
                    [_disabledProductIdentifiers addObject:[self getDisabledId:productIdentifier]];

                if ([[self.class inAppsMaps] containsObject:productIdentifier])
                    _isAnyMapPurchased = YES;
                
                [_purchasedProductIdentifiers addObject:productIdentifier];
                OALog(@"Previously purchased: %@", productIdentifier);
                
            } else {
                OALog(@"Not purchased: %@", productIdentifier);
            }
        }
        [self buildFunctionalAddonsArray];
    }
    return self;
    
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler
{
    // Add self as transaction observer
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    _completionHandler = [completionHandler copy];
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (void)disableProduct:(NSString *)productIdentifier
{
    [_disabledProductIdentifiers addObject:[self getDisabledId:productIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[self getDisabledId:productIdentifier]];
    [self buildFunctionalAddonsArray];
    [[[OsmAndApp instance] addonsSwitchObservable] notifyEventWithKey:kInAppId_Addon_TrackRecording andValue:[NSNumber numberWithBool:NO]];
}

- (void)enableProduct:(NSString *)productIdentifier
{
    [_disabledProductIdentifiers removeObject:[self getDisabledId:productIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[self getDisabledId:productIdentifier]];
    [self buildFunctionalAddonsArray];
    [[[OsmAndApp instance] addonsSwitchObservable] notifyEventWithKey:kInAppId_Addon_TrackRecording andValue:[NSNumber numberWithBool:YES]];
}

- (BOOL)isProductDisabled:(NSString *)productIdentifier
{
    return [_disabledProductIdentifiers containsObject:[self getDisabledId:productIdentifier]];
}

- (BOOL)productPurchasedIgnoreDisable:(NSString *)productIdentifier
{
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (BOOL)productPurchased:(NSString *)productIdentifier
{
    return [_purchasedProductIdentifiers containsObject:productIdentifier] && ![_disabledProductIdentifiers containsObject:[self getDisabledId:productIdentifier]];
}

- (void)buildFunctionalAddonsArray
{
    //[_purchasedProductIdentifiers addObject:kInAppId_Addon_Parking];
    //[_purchasedProductIdentifiers addObject:kInAppId_Addon_TrackRecording];

    NSMutableArray *arr = [NSMutableArray array];

    if ([self productPurchased:kInAppId_Addon_Parking])
    {
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_Parking_Set titleShort:OALocalizedString(@"add_parking_short") titleWide:OALocalizedString(@"add_parking") imageName:@"parking_position.png"];
        addon.sortIndex = 0;
        [arr addObject:addon];
    }

    if ([self productPurchased:kInAppId_Addon_TrackRecording])
    {
        /*
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_TrackRecording_Add_Waypoint titleShort:OALocalizedString(@"add_waypoint_short") titleWide:OALocalizedString(@"add_waypoint") imageName:@"add_waypoint_to_track.png"];
        addon.sortIndex = 1;
        [arr addObject:addon];
        */
    }
    
    [arr sortUsingComparator:^NSComparisonResult(OAFunctionalAddon *obj1, OAFunctionalAddon *obj2) {
        return obj1.sortIndex < obj2.sortIndex ? NSOrderedAscending : NSOrderedDescending;
    }];
    
    if (arr.count == 1)
        _singleAddon = arr[0];
    else
        _singleAddon = nil;
    
    _functionalAddons = [NSArray arrayWithArray:arr];
}

- (void)buyProduct:(SKProduct *)product
{
    OALog(@"Buying %@...", product.productIdentifier);
    
    _restoringPurchases = NO;
    
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

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
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
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductsRestoredNotification object:[NSNumber numberWithInteger:_transactionErrors] userInfo:nil];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    OALog(@"completeTransaction - %@", transaction.payment.productIdentifier);
    
    if ([[self.class inAppsMaps] containsObject:transaction.payment.productIdentifier])
        _isAnyMapPurchased = YES;

    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    OALog(@"restoreTransaction - %@", transaction.originalTransaction.payment.productIdentifier);
    
    if ([[self.class inAppsMaps] containsObject:transaction.originalTransaction.payment.productIdentifier])
        _isAnyMapPurchased = YES;

    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    OALog(@"failedTransaction - %@", transaction.payment.productIdentifier);
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        OALog(@"Transaction error: %@", transaction.error.localizedDescription);

        [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:transaction.payment.productIdentifier userInfo:nil];
    
    } else {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchaseFailedNotification object:nil userInfo:nil];
    }

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];

    [self buildFunctionalAddonsArray];
}

- (void)restoreCompletedTransactions {
    
    _restoringPurchases = YES;
    _transactionErrors = 0;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end