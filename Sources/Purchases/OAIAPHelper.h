//
//  OAIAPHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#define kFreeMapsAvailableTotal 7

@class OAProduct, OASubscription, OASubscriptionList, OAFunctionalAddon;

UIKIT_EXTERN NSString *const OAIAPProductsRequestSucceedNotification;
UIKIT_EXTERN NSString *const OAIAPProductsRequestFailedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchasedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchaseFailedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchaseDeferredNotification;
UIKIT_EXTERN NSString *const OAIAPProductsRestoredNotification;
UIKIT_EXTERN NSString *const OAIAPRequestPurchaseProductNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success);

@interface OASubscriptionState : NSObject

+ (OASubscriptionState *) UNDEFINED;
+ (OASubscriptionState *) ACTIVE;
+ (OASubscriptionState *) CANCELLED;
+ (OASubscriptionState *) IN_GRACE_PERIOD;
+ (OASubscriptionState *) ON_HOLD;
+ (OASubscriptionState *) PAUSED;
+ (OASubscriptionState *) EXPIRED;

+ (OASubscriptionState *) getByStateStr:(NSString *)stateStr;

@property (nonatomic, readonly) NSString *stateStr;
@property (nonatomic, readonly) NSString *localizedName;

- (BOOL) isGone;
- (BOOL) isActive;

@end

typedef NS_ENUM(NSInteger, EOASubscriptionOrigin) {
    EOASubscriptionOriginUndefined = -1,
    EOASubscriptionOriginAndroid,
    EOASubscriptionOriginPromo,
    EOASubscriptionOriginIOS,
    EOASubscriptionOriginAmazon,
    EOASubscriptionOriginHuawei
};

typedef NS_ENUM(NSInteger, EOASubscriptionDuration) {
    EOASubscriptionDurationUndefined = -1,
    EOASubscriptionDurationMonthly,
    EOASubscriptionDurationYearly,
    EOASubscriptionDuration6Months,
    EOASubscriptionDuration3Months
};

@interface OASubscriptionStateHolder : NSObject

@property (nonatomic) OASubscriptionState *state;
@property (nonatomic, assign) long startTime;
@property (nonatomic, assign) long expireTime;
@property (nonatomic, assign) EOASubscriptionOrigin origin;
@property (nonatomic, assign) EOASubscriptionDuration duration;

@end

@interface OAIAPHelper : NSObject

@property (nonatomic, readonly) OAProduct *skiMap;
@property (nonatomic, readonly) OAProduct *nautical;
@property (nonatomic, readonly) OAProduct *trackRecording;
@property (nonatomic, readonly) OAProduct *parking;
@property (nonatomic, readonly) OAProduct *wiki;
@property (nonatomic, readonly) OAProduct *srtm;
@property (nonatomic, readonly) OAProduct *osmEditing;
@property (nonatomic, readonly) OAProduct *mapillary;
@property (nonatomic, readonly) OAProduct *weather;
@property (nonatomic, readonly) OAProduct *sensors;
@property (nonatomic, readonly) OAProduct *carplay;
@property (nonatomic, readonly) OAProduct *osmandDevelopment;

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
@property (nonatomic, readonly) OASubscription *proMonthly;
@property (nonatomic, readonly) OASubscription *proAnnually;
@property (nonatomic, readonly) OASubscription *mapsAnnually;
@property (nonatomic, readonly) OAProduct *mapsFull;
@property (nonatomic, readonly) OASubscriptionList *subscriptionList;

@property (nonatomic, readonly) NSArray<OAProduct *> *inApps;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsFree;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsPurchased;

@property (nonatomic, readonly) NSArray<OAProduct *> *inAppMaps;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppMapsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppMapsPurchased;

@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddons;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPurchased;

+ (OAIAPHelper *) sharedInstance;

@property (nonatomic, readonly) NSArray<OAFunctionalAddon *> *functionalAddons;
@property (nonatomic, readonly) OAFunctionalAddon *singleAddon;

- (void) resetTestPurchases;
- (void) requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void) buyProduct:(OAProduct *)product;
- (void) restoreCompletedTransactions;

- (void) enableProduct:(NSString *)productIdentifier;
- (void) disableProduct:(NSString *)productIdentifier;
- (OAProduct *) product:(NSString *)productIdentifier;
- (OASubscription *) getCheapestMonthlySubscription;
- (NSArray<OASubscription *> *) getEverMadeSubscriptions;
- (NSArray<OAProduct *> *) getEverMadeMainPurchases;

- (BOOL) productsLoaded;

- (NSArray *) getSubscriptionStateByOrderId:(NSString *)orderId;
- (NSString *) getOrderIdByDeviceIdAndToken;
- (OASubscription *) getAnyPurchasedOsmAndProSubscription;
- (BOOL) checkBackupSubscriptions;

- (void) onBackupPurchaseRequested;
- (void) checkBackupPurchase:(void(^)(BOOL))onComplete;
- (void) checkBackupPurchase;

- (BOOL) isCarPlayAvailable;

+ (int) freeMapsAvailable;
+ (void) increaseFreeMapsCount:(int)count;
+ (void) decreaseFreeMapsCount;

+ (BOOL) isPaidVersion;

+ (BOOL) isSubscribedToMaps;
+ (BOOL) isSubscribedToLiveUpdates;
+ (BOOL) isSubscribedToOsmAndPro;
+ (BOOL) isSubscribedCrossPlatform;
+ (BOOL) isSubscribedToMapperUpdates;
+ (BOOL) isOsmAndProAvailable;

+ (BOOL) isFullVersionPurchased;
+ (BOOL) isDepthContoursPurchased;
+ (BOOL) isContourLinesPurchased;
+ (BOOL) isWikipediaPurchased;
+ (BOOL) isSensorPurchased;

+ (BOOL) isLiveUpdatesSubscription:(OASubscription *)subscription;
+ (BOOL) isOsmAndProSubscription:(OASubscription *)subscription;
+ (BOOL) isMapsSubscription:(OASubscription *)subscription;
+ (BOOL) isFullVersion:(OAProduct *)product;

@end
