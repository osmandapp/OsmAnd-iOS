//
//  OAIAPHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIAPHelper.h"
#import "OALog.h"
#import "OsmAndApp.h"
#import "OAAnalyticsHelper.h"
#import "OANetworkUtilities.h"
#import "Localization.h"
#import "OADonationSettingsViewController.h"
#import "OACheckBackupSubscriptionTask.h"

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

#define CARPLAY_START_DATE_SEC (10L * 60L * 60L * 24L) // 10 days
#define PURCHASE_VALIDATION_PERIOD_SEC 60 * 60 * 24 // daily

typedef void (^RequestActiveProductsCompletionHandler)(NSArray<OAProduct *> *products, NSDictionary<NSString *, NSDate *> *expirationDates, BOOL success);

@interface OAIAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic) BOOL subscribedToLiveUpdates;

@end

@implementation OASubscriptionState

static OASubscriptionState *UNDEFINED;
static OASubscriptionState *ACTIVE;
static OASubscriptionState *CANCELLED;
static OASubscriptionState *IN_GRACE_PERIOD;
static OASubscriptionState *ON_HOLD;
static OASubscriptionState *PAUSED;
static OASubscriptionState *EXPIRED;

- (instancetype) initWithStateStr:(NSString *)stateStr localizedName:(NSString *)localizedName
{
    self = [super init];
    if (self) {
        _localizedName = localizedName;
        _stateStr = stateStr;
    }
    return self;
}

+ (OASubscriptionState *) UNDEFINED
{
    if (!UNDEFINED)
        UNDEFINED = [[OASubscriptionState alloc] initWithStateStr:@"undefined" localizedName:OALocalizedString(@"shared_string_undefined")];
    return UNDEFINED;
}

+ (OASubscriptionState *) ACTIVE
{
    if (!ACTIVE)
        ACTIVE = [[OASubscriptionState alloc] initWithStateStr:@"active" localizedName:OALocalizedString(@"menu_active_trips")];
    return ACTIVE;
}

+ (OASubscriptionState *) CANCELLED
{
    if (!CANCELLED)
        CANCELLED = [[OASubscriptionState alloc] initWithStateStr:@"cancelled" localizedName:OALocalizedString(@"shared_string_cancelled")];
    return CANCELLED;
}

+ (OASubscriptionState *) IN_GRACE_PERIOD
{
    if (!IN_GRACE_PERIOD)
        IN_GRACE_PERIOD = [[OASubscriptionState alloc] initWithStateStr:@"in_grace_period" localizedName:OALocalizedString(@"in_grace_period")];
    return IN_GRACE_PERIOD;
}

+ (OASubscriptionState *) ON_HOLD
{
    if (!ON_HOLD)
        ON_HOLD = [[OASubscriptionState alloc] initWithStateStr:@"on_hold" localizedName:OALocalizedString(@"on_hold")];
    return ON_HOLD;
}

+ (OASubscriptionState *) PAUSED
{
    if (!PAUSED)
        PAUSED = [[OASubscriptionState alloc] initWithStateStr:@"paused" localizedName:OALocalizedString(@"paused")];
    return PAUSED;
}

+ (OASubscriptionState *) EXPIRED
{
    if (!EXPIRED)
        EXPIRED = [[OASubscriptionState alloc] initWithStateStr:@"expired" localizedName:OALocalizedString(@"expired")];
    return EXPIRED;
}

+ (NSArray<OASubscriptionState *> *) values
{
    return @[self.UNDEFINED, self.ACTIVE, self.CANCELLED, self.IN_GRACE_PERIOD, self.ON_HOLD, self.PAUSED, self.EXPIRED];
}
           
+ (OASubscriptionState *) getByStateStr:(NSString *)stateStr
{
    for (OASubscriptionState *state in self.values)
    {
        if ([state.stateStr isEqualToString:stateStr])
            return state;
    }
    return self.UNDEFINED;
}

- (BOOL) isGone
{
    return self == OASubscriptionState.ON_HOLD || self == OASubscriptionState.PAUSED || self == OASubscriptionState.EXPIRED;
}

- (BOOL) isActive
{
    return self == OASubscriptionState.ACTIVE || self == OASubscriptionState.CANCELLED || self == OASubscriptionState.IN_GRACE_PERIOD;
}

@end

@implementation OASubscriptionStateHolder

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
    
    NSTimeInterval _lastBackupPurchaseCheckTime;
    BOOL _backupPurchaseRequested;
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

+ (BOOL) isPaidVersion
{
    return [self isFullVersionPurchased]
            || [self isSubscribedToLiveUpdates]
            || [self isSubscribedToMaps]
            || [self isOsmAndProAvailable];
}

+ (BOOL) isSubscribedToMaps
{
    return [[OAAppSettings sharedManager].osmandMapsPurchased get];
}

+ (BOOL) isSubscribedToLiveUpdates
{
    return [[OAAppSettings sharedManager].liveUpdatesPurchased get] || [self isSubscribedToMapperUpdates] || [self isOsmAndProAvailable];
}

+ (BOOL) isSubscribedToOsmAndPro
{
    return [[OAAppSettings sharedManager].osmandProPurchased get];
}

+ (BOOL) isSubscribedCrossPlatform
{
    return [[OAAppSettings sharedManager].backupPurchaseActive get];
}

+ (BOOL) isSubscribedToMapperUpdates
{
    return [[OAAppSettings sharedManager].mapperLiveUpdatesExpireTime get] > [NSDate date].timeIntervalSince1970;
}

+ (BOOL) isOsmAndProAvailable
{
//#if defined(DEBUG)
//    return YES;
//#else
    return [self isSubscribedCrossPlatform]
            || [self isSubscribedToOsmAndPro];
//#endif
}

+ (BOOL) isCarPlayAvailable
{
    long time = (long) NSDate.date.timeIntervalSince1970;
    long installTime = [self getInstallTime];
    if (time >= installTime + CARPLAY_START_DATE_SEC)
        return [self isPaidVersion];

    return YES;
}

+ (long) getInstallTime
{
    NSDate *installDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"install_date"];
    long firstInstalledTime = (long) installDate.timeIntervalSince1970;
    return firstInstalledTime;
}

+ (BOOL) isFullVersionPurchased
{
    return [[OAAppSettings sharedManager].fullVersionPurchased get];
}

+ (BOOL) isDepthContoursPurchased
{
    return [self isPaidVersion]
            || [[OAAppSettings sharedManager].depthContoursPurchased get];
}

+ (BOOL) isContourLinesPurchased
{
    return [self isPaidVersion]
            || [[OAAppSettings sharedManager].contourLinesPurchased get];
}

+ (BOOL) isWikipediaPurchased
{
    return [self isPaidVersion]
            || [[OAAppSettings sharedManager].wikipediaPurchased get];
}

+ (BOOL)isLiveUpdatesSubscription:(OASubscription *)subscription
{
    return [subscription.identifierNoVersion isEqualToString:kSubscriptionId_Osm_Live_Subscription_Monthly]
            || [subscription.identifierNoVersion isEqualToString:kSubscriptionId_Osm_Live_Subscription_3_Months]
            || [subscription.identifierNoVersion isEqualToString:kSubscriptionId_Osm_Live_Subscription_Annual];
}

+ (BOOL)isOsmAndProSubscription:(OASubscription *)subscription
{
    return [subscription.identifierNoVersion isEqualToString:kSubscriptionId_Pro_Subscription_Monthly]
            || [subscription.identifierNoVersion isEqualToString:kSubscriptionId_Pro_Subscription_Annual];
}

+ (BOOL)isMapsSubscription:(OASubscription *)subscription
{
    return [subscription.identifierNoVersion isEqualToString:kSubscriptionId_Maps_Subscription_Annual];
}

+ (BOOL) isFullVersion:(OAProduct *)product
{
    return [product.productIdentifier isEqualToString:kInAppId_Maps_Full];
}

- (NSArray<OASubscription *> *) getEverMadeSubscriptions
{
    NSMutableArray<OASubscription *> *subscriptions = [NSMutableArray array];
    for (OASubscription *subscription in [self.subscriptionList getVisibleSubscriptions])
    {
        if ([subscription isPurchased] || subscription.purchaseState != PSTATE_UNKNOWN)
            [subscriptions addObject:subscription];
    }
    return subscriptions;
}

- (NSArray<OAProduct *> *) getEverMadeMainPurchases
{
    NSMutableSet<OAProduct *> *products = [NSMutableSet setWithArray:[self getEverMadeSubscriptions]];
    OAProduct *fullVersion = _products.mapsFull;
    if (fullVersion && fullVersion.isPurchased)
        [products addObject:fullVersion];
    return products.allObjects;
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

- (OAProduct *) carplay
{
    return _products.carplay;
}

- (OAProduct *) osmandDevelopment
{
    return _products.osmandDevelopment;
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

- (OASubscription *) proMonthly
{
    return _products.proMonthly;
}

- (OASubscription *) proAnnually
{
    return _products.proAnnually;
}

- (OASubscription *) mapsAnnually
{
    return _products.mapsAnnually;
}

- (OAProduct *) mapsFull
{
    return _products.mapsFull;
}

- (OASubscriptionList *) subscriptionList
{
    return _products.subscriptionList;
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

- (NSArray<OAProduct *> *) inAppsPurchased
{
    return _products.inAppsPurchased;
}

- (NSArray<OAProduct *> *) inAppAddonsPurchased
{
    return _products.inAppAddonsPurchased;
}

- (NSArray<OAProduct *> *) inAppMapsPaid
{
    return _products.inAppMapsPaid;
}

- (NSArray<OAProduct *> *) inAppMapsPurchased
{
    return _products.inAppMapsPurchased;
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
        
        // test - reset purchases
        if (TEST_LOCAL_PURCHASE)
        {
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"freeMapsAvailable"];

            [_settings.liveUpdatesPurchased set:NO];
            [_settings.osmandProPurchased set:NO];
            [_settings.osmandMapsPurchased set:NO];
            [_settings.fullVersionPurchased set:NO];
            [_settings.depthContoursPurchased set:NO];
            [_settings.contourLinesPurchased set:NO];
            [_settings.wikipediaPurchased set:NO];
            for (OAProduct *product in _products.inAppsPaid)
            {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:product.productIdentifier])
                {
                    if ([product isKindOfClass:OASubscription.class])
                    {
                        [_products setExpired:product.productIdentifier];
                    }
                    else
                    {
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:product.productIdentifier];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
            }
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
    
    [self checkBackupPurchaseIfNeeded];

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
                            [self.subscriptionList upgradeSubscription:identifier];
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

- (OASubscription *) getCheapestMonthlySubscription
{
    NSArray<OASubscription *> *subscriptions = [self.subscriptionList getVisibleSubscriptions];
    OASubscription *cheapest = nil;
    for (OASubscription *subscription in subscriptions)
    {
        if (!cheapest || subscription.monthlyPrice.doubleValue < cheapest.monthlyPrice.doubleValue)
            cheapest = subscription;
    }
    return cheapest;
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
            BOOL subscribed = NO;
            BOOL live = NO;
            BOOL pro = NO;
            BOOL maps = NO;
            BOOL full = NO;
            BOOL depth = NO;
            BOOL contour = NO;
            BOOL wiki = NO;
            NSMutableArray<OASubscription *> *purchasedSubs = [NSMutableArray array];
            for (OAProduct *product in products)
            {
                BOOL isSubscription = [product isKindOfClass:[OASubscription class]];
                if (!subscribed && isSubscription)
                    subscribed = YES;

                if (isSubscription)
                {
                    OASubscription *s = (OASubscription *)product;
                    [purchasedSubs addObject:s];
                    if ([OAIAPHelper isLiveUpdatesSubscription:s])
                        live = YES;
                    else if ([OAIAPHelper isOsmAndProSubscription:s])
                        pro = YES;
                    else if ([OAIAPHelper isMapsSubscription:s])
                        maps = YES;
                }
                else if ([OAIAPHelper isFullVersion:product])
                {
                    full = YES;
                }
                else if ([product.productIdentifier isEqualToString:kInAppId_Addon_Nautical])
                {
                    depth = YES;
                }
                else if ([product.productIdentifier isEqualToString:kInAppId_Addon_Srtm])
                {
                    contour = YES;
                }
                else if ([product.productIdentifier isEqualToString:kInAppId_Addon_Wiki])
                {
                    wiki = YES;
                }

                BOOL wasPurchased = [product isPurchased];
                [_products setPurchased:product.productIdentifier];
                if (!wasPurchased)
                    [purchased addObject:product];
            }
            NSArray<OASubscription *> *subs = [self.subscriptionList getPurchasedSubscriptions];
            
            for (OASubscription *s in subs)
            {
                if ([purchasedSubs containsObject:s])
                {
                    [s setPurchaseCancelledTime:0];
                    continue;
                }
                
                [_products setExpired:s.productIdentifier];
                NSTimeInterval subscriptionCancelledTime = s.purchaseCancelledTime;
                
                if (subscriptionCancelledTime == 0)
                {
                    subscriptionCancelledTime = [[NSDate date] timeIntervalSince1970];
                    [s setPurchaseCancelledTime:subscriptionCancelledTime];
                    [_settings.liveUpdatesPurchaseCancelledFirstDlgShown set:NO];
                    [_settings.liveUpdatesPurchaseCancelledSecondDlgShown set:NO];
                }
                else if ([[NSDate date] timeIntervalSince1970] - subscriptionCancelledTime > kSubscriptionHoldingTimeMsec)
                {
                    if ([self.class isLiveUpdatesSubscription:s])
                    {
                        BOOL livePurchased = NO;
                        for (OASubscription *s in purchasedSubs)
                        {
                            if ([self.class isLiveUpdatesSubscription:s])
                            {
                                livePurchased = YES;
                                break;
                            }
                        }
                        if (!livePurchased)
                            [_settings.liveUpdatesPurchased set:NO];
                    }
                    else if ([self.class isOsmAndProSubscription:s])
                    {
                        BOOL proPurchased = NO;
                        for (OASubscription *s in purchasedSubs)
                        {
                            if ([self.class isOsmAndProSubscription:s])
                            {
                                proPurchased = YES;
                                break;
                            }
                        }
                        if (!proPurchased)
                            [_settings.osmandProPurchased set:NO];
                    }
                    else if ([self.class isMapsSubscription:s])
                    {
                        BOOL mapsPurchased = NO;
                        for (OASubscription *s in purchasedSubs)
                        {
                            if ([self.class isOsmAndProSubscription:s])
                            {
                                mapsPurchased = YES;
                                break;
                            }
                        }
                        if (!mapsPurchased)
                            [_settings.osmandMapsPurchased set:NO];
                    }
                    //if (!isDepthContoursPurchased(ctx))
                    //    ctx.getSettings().getCustomRenderBooleanProperty("depthContours").set(false);
                }
            }
            if (subscribed)
            {
                for (OASubscription *s in purchasedSubs)
                {
                    [s setPurchaseCancelledTime:0];
                }
            }

            [_settings.liveUpdatesPurchased set:live];
            [_settings.osmandProPurchased set:pro];
            [_settings.osmandMapsPurchased set:maps];
            [_settings.fullVersionPurchased set:full];
            [_settings.depthContoursPurchased set:depth];
            [_settings.contourLinesPurchased set:contour];
            [_settings.wikipediaPurchased set:wiki];

            for (OAProduct *p in purchased)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:p.productIdentifier userInfo:nil];
            }
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
    BOOL validateProducts = NO;
    dispatch_group_t group = dispatch_group_create();
    for (SKPaymentTransaction * transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
            {
                dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    [self completeTransaction:transaction];
                });
                validateProducts |= YES;
                break;
            }
            case SKPaymentTransactionStateFailed:
            {
                _transactionErrors++;
                [self failedTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored:
            {
                dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    [self restoreTransaction:transaction];
                });
                validateProducts |= YES;
                break;
            }
            case SKPaymentTransactionStateDeferred:
            {
                [self deferredTransaction:transaction];
            }
            default:
            {
                break;
            }
        }
    }
    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        if (validateProducts)
            [self requestProductsWithCompletionHandler:nil];
    });
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
        NSLog(@"%@ product purchased.", product.localizedTitle);

        // test - emulate purchase
        if (TEST_LOCAL_PURCHASE)
        {
            [_products setPurchased:productIdentifier];

            if ([product isKindOfClass:OASubscription.class])
            {
                if ([self.class isLiveUpdatesSubscription:product])
                    [_settings.liveUpdatesPurchased set:YES];
                else if ([self.class isOsmAndProSubscription:product])
                    [_settings.osmandProPurchased set:YES];
                else if ([self.class isMapsSubscription:product])
                    [_settings.osmandMapsPurchased set:YES];
            }
            else if ([self.class isFullVersion:product])
            {
                [_settings.fullVersionPurchased set:YES];
            }
            else if ([product.productIdentifier isEqualToString:kInAppId_Addon_Nautical])
            {
                [_settings.depthContoursPurchased set:YES];
            }
            else if ([product.productIdentifier isEqualToString:kInAppId_Addon_Srtm])
            {
                [_settings.contourLinesPurchased set:YES];
            }
            else if ([product.productIdentifier isEqualToString:kInAppId_Addon_Wiki])
            {
                [_settings.wikipediaPurchased set:YES];
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:OAIAPProductPurchasedNotification object:productIdentifier userInfo:nil];
            return;
        }

        if ([product isKindOfClass:[OASubscription class]])
        {
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
                
                [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/purchased" params:params post:YES async:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
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
                                     
                                     _settings.lastReceiptValidationDate = [NSDate dateWithTimeIntervalSince1970:0];
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
    }
}

- (void) restoreCompletedTransactions
{
    _settings.lastReceiptValidationDate = [NSDate dateWithTimeIntervalSince1970:0];
    _restoringPurchases = YES;
    _transactionErrors = 0;

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL) needValidateReceipt
{
    if (!_settings.billingUserId.get)
        return YES;
    
    NSTimeInterval lastReceiptValidationTimeInterval = [[[NSDate alloc] init] timeIntervalSinceDate:_settings.lastReceiptValidationDate];
    NSArray<OASubscription *> *subscriptions = [_products.subscriptionList getPurchasedSubscriptions];
    for (OASubscription *subscription in subscriptions)
    {
        NSDate *expDate = subscription.expirationDate;
        if (!expDate)
            return YES;

        if ([[[NSDate alloc] init] timeIntervalSinceDate:expDate] > 0 && lastReceiptValidationTimeInterval > kReceiptValidationMinPeriod)
            return YES;
    }
    
    return subscriptions.count == 0 ? lastReceiptValidationTimeInterval > kReceiptValidationMaxPeriod : NO;
}

- (BOOL) needRequestBackupPurchase
{
    return !_backupPurchaseRequested || NSDate.date.timeIntervalSince1970 - _lastBackupPurchaseCheckTime > PURCHASE_VALIDATION_PERIOD_SEC;
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
    NSArray<OASubscription *> *subscriptions = [_products.subscriptionList getVisibleSubscriptions];
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
                                     OASubscription *subscription = [_products.subscriptionList getSubscriptionByIdentifier:paymentDiscount.productIdentifier];
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

- (NSArray *) getSubscriptionStateByOrderId:(NSString *)orderId
{
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"orderId"] = orderId;
    __block NSArray *res;
    __block BOOL alreadyFinished = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/api/subscriptions/get" params:params post:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200 && data)
        {
            NSError *jsonParsingError = nil;
            NSArray *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
            if (!jsonParsingError)
            {
                NSDictionary<NSString *, OASubscriptionStateHolder *> *stateHolders = [self parseSubscriptionStates:resultJson];
                if (stateHolders.count > 0)
                {
                    NSString *key = stateHolders.allKeys.firstObject;
                    res = @[key, stateHolders[key]];
                }
            }
        }
        else
        {
            res = nil;
        }
        alreadyFinished = YES;
        dispatch_semaphore_signal(semaphore);
    }];
    if (!alreadyFinished)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return res;
}

- (NSDictionary<NSString *, OASubscriptionStateHolder *> *)parseSubscriptionStates:(NSArray *)subscriptionsStateJson
{
    NSMutableDictionary<NSString *, OASubscriptionStateHolder *> *subscriptionStateMap = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < subscriptionsStateJson.count; i++)
    {
        NSDictionary *subObj = subscriptionsStateJson[i];
        NSString *sku = [subObj[@"sku"] stringValue];
        NSString *state = [subObj[@"state"] stringValue];
        
        if (sku.length > 0 && state.length > 0)
        {
            OASubscriptionStateHolder *stateHolder = [[OASubscriptionStateHolder alloc] init];
            stateHolder.state = [OASubscriptionState getByStateStr:state];
            stateHolder.startTime = [subObj[@"start_time"] stringValue].integerValue / 1000;
            stateHolder.expireTime = [subObj[@"expire_time"] stringValue].integerValue / 1000;
            stateHolder.origin = [self getSubscriptionOriginBySku:sku];
            subscriptionStateMap[sku] = stateHolder;
        }
    }
    return subscriptionStateMap;
}

- (EOASubscriptionOrigin) getSubscriptionOriginBySku:(NSString *)sku
{
    if ([sku isEqualToString:@"promo_website"])
        return EOASubscriptionOriginPromo;
    else if ([sku.lowerCase hasPrefix:@"osmand_"])
        return EOASubscriptionOriginAndroid;
    else if ([sku.lowerCase hasPrefix:@"net.osmand.maps."])
        return EOASubscriptionOriginIOS;
    return EOASubscriptionOriginUndefined;
}

- (NSString *) getOrderIdByDeviceIdAndToken
{
    OAAppSettings *_settings = OAAppSettings.sharedManager;
    __block NSString *orderId = nil;
    NSString *deviceId = [_settings.backupDeviceId get];
    NSString *accessToken = [_settings.backupAccessToken get];
    if (deviceId.length > 0 && accessToken.length > 0)
    {
        NSDictionary<NSString *, NSString *> *params = @{
            @"deviceid" : deviceId,
            @"accessToken" : accessToken
        };
        __block BOOL alreadyFinished = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/userdata/user-validate-sub" params:params post:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (((NSHTTPURLResponse *)response).statusCode == 200 && data)
            {
                NSError *jsonParsingError = nil;
                NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
                if (!jsonParsingError)
                {
                    orderId = [resultJson[@"orderid"] stringValue];
                }
                else
                {
                    NSLog(@"Subscription validation json error");
                }
            }
            alreadyFinished = YES;
            dispatch_semaphore_signal(semaphore);
        }];
        if (!alreadyFinished)
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    return orderId;
}

- (BOOL) checkBackupSubscriptions
{
    BOOL subscriptionActive = NO;
    NSString *promocode = [_settings.backupPromocode get];
    if (promocode.length > 0)
    {
        subscriptionActive = [self checkSubscriptionByOrderId:promocode];
    }
    if (!subscriptionActive)
    {
        NSString *orderId = [self getOrderIdByDeviceIdAndToken];
        if (orderId.length > 0)
        {
            subscriptionActive = [self checkSubscriptionByOrderId:orderId];
        }
    }
    return subscriptionActive;
}

- (BOOL) checkSubscriptionByOrderId:(NSString *)orderId
{
    NSArray *entry = [self getSubscriptionStateByOrderId:orderId];
    if (entry != nil)
    {
        OASubscriptionStateHolder *stateHolder = entry.lastObject;
        return stateHolder.state.isActive;
    }
    return NO;
}

- (void) onBackupPurchaseRequested
{
    _backupPurchaseRequested = YES;
    _lastBackupPurchaseCheckTime = NSDate.date.timeIntervalSince1970;
}

- (void) checkBackupPurchase
{
    OACheckBackupSubscriptionTask *t = [[OACheckBackupSubscriptionTask alloc] init];
    [t execute:nil];
}

- (void) checkBackupPurchaseIfNeeded
{
    if ([self needRequestBackupPurchase])
    {
        [self checkBackupPurchase];
    }
}

- (OASubscription *) getAnyPurchasedOsmAndProSubscription
{
    NSArray<OASubscription *> *allSubscriptions = _products.subscriptionList.getAllSubscriptions;
    for (OASubscription *subscription in allSubscriptions)
    {
        if ([self.class isOsmAndProSubscription:subscription] && subscription.isPurchased)
            return subscription;
    }
    return nil;
}

@end
