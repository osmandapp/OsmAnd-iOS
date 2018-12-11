//
//  OAProducts.h
//  OsmAnd
//
//  Created by Alexey on 11/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;

typedef NS_ENUM(NSInteger, EOAPurchaseState)
{
    PSTATE_UNKNOWN = 0,
    PSTATE_PURCHASED,
    PSTATE_NOT_PURCHASED
};

@interface OAFunctionalAddon : NSObject

@property (nonatomic, readonly) NSString *addonId;
@property (nonatomic, readonly) NSString *titleShort;
@property (nonatomic, readonly) NSString *titleWide;
@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, assign) NSInteger sortIndex;
@property (nonatomic, assign) NSInteger tag;

- (instancetype) initWithAddonId:(NSString *)addonId titleShort:(NSString *)titleShort titleWide:(NSString *)titleWide imageName:(NSString *)imageName;

@end

@interface OAProduct : NSObject

@property (nonatomic, readonly) NSString *productIdentifier;
@property (nonatomic, readonly) NSString *localizedDescription;
@property (nonatomic, readonly) NSString *localizedDescriptionExt;
@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSDecimalNumber *price;
@property (nonatomic, readonly) NSLocale *priceLocale;
@property (nonatomic, readonly) EOAPurchaseState purchaseState; // PSTATE_UNKNOWN

@property (nonatomic, readonly) SKProduct *skProduct;

- (instancetype) initWithSkProduct:(SKProduct *)skProduct;
- (instancetype) initWithIdentifier:(NSString *)productIdentifier title:(NSString *)title desc:(NSString *)desc price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale;
- (instancetype) initWithIdentifier:(NSString *)productIdentifier;

- (void) setSkProduct:(SKProduct *)skProduct;

- (NSDecimalNumber *) getDefaultPrice;
- (BOOL) isPurchased;
- (BOOL) fetchRequired;
- (NSAttributedString *) getTitle;
- (NSAttributedString *) getDescription;

@end

@interface OASubscription : OAProduct

@property (nonatomic, readonly) NSString *identifierNoVersion;
@property (nonatomic, readonly) NSString *subscriptionPeriod;
@property (nonatomic, readonly) NSDecimalNumber *monthlyPrice;
@property (nonatomic, readonly) NSDecimalNumber *defaultMonthlyPrice;

@property (nonatomic, readonly) BOOL donationSupported;

- (instancetype) initWithIdentifierNoVersion:(NSString *)identifierNoVersion version:(int)version;
- (NSArray<OASubscription *> *) getUpgrades;
- (BOOL) isAnyPurchased;

@end

@interface OASubscriptionList : NSObject

@end

@interface OAProducts : NSObject

@property (nonatomic, readonly) OAProduct *skiMap;
@property (nonatomic, readonly) OAProduct *nautical;
@property (nonatomic, readonly) OAProduct *trackRecording;
@property (nonatomic, readonly) OAProduct *parking;
@property (nonatomic, readonly) OAProduct *wiki;
@property (nonatomic, readonly) OAProduct *srtm;
@property (nonatomic, readonly) OAProduct *tripPlanning;

@property (nonatomic, readonly) OAProduct *allWorld;
@property (nonatomic, readonly) OAProduct *russia;
@property (nonatomic, readonly) OAProduct *africa;
@property (nonatomic, readonly) OAProduct *asia;
@property (nonatomic, readonly) OAProduct *australia;
@property (nonatomic, readonly) OAProduct *europe;
@property (nonatomic, readonly) OAProduct *centralAmerica;
@property (nonatomic, readonly) OAProduct *northAmerica;
@property (nonatomic, readonly) OAProduct *southAmerica;

@property (nonatomic, readonly) NSArray<OAProduct *> *inApps;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppMaps;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddons;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppPurchased;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPurchased;

@property (nonatomic, readonly) OASubscription *monthlyLiveUpdates;
@property (nonatomic, readonly) OASubscriptionList *liveUpdates;

@end

NS_ASSUME_NONNULL_END
