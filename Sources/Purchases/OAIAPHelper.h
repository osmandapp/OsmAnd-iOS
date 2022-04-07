//
//  OAIAPHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "OAProducts.h"

#define kFreeMapsAvailableTotal 5

UIKIT_EXTERN NSString *const OAIAPProductsRequestSucceedNotification;
UIKIT_EXTERN NSString *const OAIAPProductsRequestFailedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchasedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchaseFailedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchaseDeferredNotification;
UIKIT_EXTERN NSString *const OAIAPProductsRestoredNotification;
UIKIT_EXTERN NSString *const OAIAPRequestPurchaseProductNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success);

@interface OAIAPHelper : NSObject

@property (nonatomic, readonly) OAProduct *skiMap;
@property (nonatomic, readonly) OAProduct *nautical;
@property (nonatomic, readonly) OAProduct *trackRecording;
@property (nonatomic, readonly) OAProduct *parking;
@property (nonatomic, readonly) OAProduct *wiki;
@property (nonatomic, readonly) OAProduct *srtm;
@property (nonatomic, readonly) OAProduct *osmEditing;
@property (nonatomic, readonly) OAProduct *mapillary;
@property (nonatomic, readonly) OAProduct *openPlaceReviews;
@property (nonatomic, readonly) OAProduct *weather;

@property (nonatomic, readonly) OAProduct *allWorld;
@property (nonatomic, readonly) OAProduct *russia;
@property (nonatomic, readonly) OAProduct *antarctica;
@property (nonatomic, readonly) OAProduct *africa;
@property (nonatomic, readonly) OAProduct *asia;
@property (nonatomic, readonly) OAProduct *australia;
@property (nonatomic, readonly) OAProduct *europe;
@property (nonatomic, readonly) OAProduct *centralAmerica;
@property (nonatomic, readonly) OAProduct *northAmerica;
@property (nonatomic, readonly) OAProduct *southAmerica;

@property (nonatomic, readonly) OASubscription *monthlyLiveUpdates;
@property (nonatomic, readonly) OASubscriptionList *liveUpdates;
@property (nonatomic, readonly) BOOL subscribedToLiveUpdates;

@property (nonatomic, readonly) NSArray<OAProduct *> *inApps;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppMaps;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddons;

@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsFree;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsPurchased;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPurchased;

+ (OAIAPHelper *) sharedInstance;

@property (nonatomic, readonly) BOOL isAnyMapPurchased;

@property (nonatomic, readonly) NSArray<OAFunctionalAddon *> *functionalAddons;
@property (nonatomic, readonly) OAFunctionalAddon *singleAddon;

- (void) requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void) buyProduct:(OAProduct *)product;
- (void) restoreCompletedTransactions;

- (void) enableProduct:(NSString *)productIdentifier;
- (void) disableProduct:(NSString *)productIdentifier;
- (OAProduct *) product:(NSString *)productIdentifier;
- (OASubscription *) getCheapestMonthlySubscription;

- (BOOL) productsLoaded;

+ (int) freeMapsAvailable;
+ (void) increaseFreeMapsCount:(int)count;
+ (void) decreaseFreeMapsCount;

@end
