//
//  OAProducts.h
//  OsmAnd
//
//  Created by Alexey on 11/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Map regions inapp ids
#define kInAppId_Region_Africa @"net.osmand.maps.inapp.region.africa"
#define kInAppId_Region_Russia @"net.osmand.maps.inapp.region.russia"
#define kInAppId_Region_Asia @"net.osmand.maps.inapp.region.asia"
#define kInAppId_Region_Australia @"net.osmand.maps.inapp.region.australia"
#define kInAppId_Region_Europe @"net.osmand.maps.inapp.region.europe"
#define kInAppId_Region_Central_America @"net.osmand.maps.inapp.region.centralamerica"
#define kInAppId_Region_North_America @"net.osmand.maps.inapp.region.northamerica"
#define kInAppId_Region_South_America @"net.osmand.maps.inapp.region.southamerica"
#define kInAppId_Region_All_World @"net.osmand.maps.inapp.region.allworld"

// Map regions efault prices (EUR)
#define kInAppId_Region_Africa_Default_Price 3.49
#define kInAppId_Region_Russia_Default_Price 3.49
#define kInAppId_Region_Asia_Default_Price 3.49
#define kInAppId_Region_Australia_Default_Price 3.49
#define kInAppId_Region_Europe_Default_Price 3.49
#define kInAppId_Region_Central_America_Default_Price 3.49
#define kInAppId_Region_North_America_Default_Price 3.49
#define kInAppId_Region_South_America_Default_Price 3.49
#define kInAppId_Region_All_World_Default_Price 6.99

// Addons inapp ids
#define kInAppId_Addon_SkiMap @"net.osmand.maps.inapp.addon.skimap"
#define kInAppId_Addon_Nautical @"net.osmand.maps.inapp.addon.nautical"
#define kInAppId_Addon_TrackRecording @"net.osmand.maps.inapp.addon.track_recording"
#define kInAppId_Addon_Parking @"net.osmand.maps.inapp.addon.parking"
#define kInAppId_Addon_Wiki @"net.osmand.maps.inapp.addon.wiki"
#define kInAppId_Addon_Srtm @"net.osmand.maps.inapp.addon.srtm"
#define kInAppId_Addon_TripPlanning @"net.osmand.maps.inapp.addon.trip_planning"

// Addons default prices (EUR)
#define kInAppId_Addon_SkiMap_Default_Price 0.0
#define kInAppId_Addon_Nautical_Default_Price 1.09
#define kInAppId_Addon_TrackRecording_Default_Price 0.0
#define kInAppId_Addon_Parking_Default_Price 0.0
#define kInAppId_Addon_Wiki_Default_Price 0.0
#define kInAppId_Addon_Srtm_Default_Price 3.49
#define kInAppId_Addon_TripPlanning_Default_Price 0.0

// Addons internal ids
#define kId_Addon_TrackRecording_Add_Waypoint @"addon.track_recording.add_waypoint"
#define kId_Addon_Parking_Set @"addon.parking.set"

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
@property (nonatomic, readonly, nullable) NSDecimalNumber *price;
@property (nonatomic, readonly, nullable) NSLocale *priceLocale;
@property (nonatomic, readonly) EOAPurchaseState purchaseState; // PSTATE_UNKNOWN
@property (nonatomic, readonly) BOOL free;
@property (nonatomic, readonly) BOOL disabled;
@property (nonatomic, readonly, nullable) NSString *formattedPrice;

@property (nonatomic) SKProduct *skProduct;

- (instancetype) initWithSkProduct:(SKProduct *)skProduct;
- (instancetype) initWithIdentifier:(NSString *)productIdentifier title:(NSString *)title desc:(NSString *)desc price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale;
- (instancetype) initWithIdentifier:(NSString *)productIdentifier;

- (NSDecimalNumber *) getDefaultPrice;
- (BOOL) isPurchased;
- (BOOL) isActive;
- (BOOL) fetchRequired;
- (NSAttributedString *) getTitle;
- (NSAttributedString *) getDescription;
- (NSString *) productIconName;
- (NSString *) productScreenshotName;

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

// Addons

@interface OASkiMapProduct : OAProduct
@end

@interface OANauticalProduct : OAProduct
@end

@interface OATrackRecordingProduct : OAProduct
@end

@interface OAParkingProduct : OAProduct
@end

@interface OAWikiProduct : OAProduct
@end

@interface OASrtmProduct : OAProduct
@end

@interface OATripPlanningProduct : OAProduct
@end

// Map regions

@interface OAAllWorldProduct : OAProduct
@end

@interface OARussiaProduct : OAProduct
@end

@interface OAAfricaProduct : OAProduct
@end

@interface OAAsiaProduct : OAProduct
@end

@interface OAAustraliaProduct : OAProduct
@end

@interface OAEuropeProduct : OAProduct
@end

@interface OACentralAmericaProduct : OAProduct
@end

@interface OANorthAmericaProduct : OAProduct
@end

@interface OASouthAmericaProduct : OAProduct
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

@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsFree;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPaid;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppsPurchased;
@property (nonatomic, readonly) NSArray<OAProduct *> *inAppAddonsPurchased;
@property (nonatomic, readonly) BOOL anyMapPurchased;

@property (nonatomic, readonly) NSArray<OAFunctionalAddon *> *functionalAddons;
@property (nonatomic, readonly) OAFunctionalAddon *singleAddon;

@property (nonatomic, readonly) OASubscription *monthlyLiveUpdates;
@property (nonatomic, readonly) OASubscriptionList *liveUpdates;

+ (NSSet<NSString *> *) getProductIdentifiers:(NSArray<OAProduct *> *)products;
- (OAProduct *) getProduct:(NSString *)productIdentifier;
- (BOOL) updateProduct:(SKProduct *)skProduct;
- (BOOL) setPurchased:(NSString * _Nonnull)productIdentifier;
- (void) disableProduct:(OAProduct *)product;
- (void) enableProduct:(OAProduct *)product;

@end

NS_ASSUME_NONNULL_END
