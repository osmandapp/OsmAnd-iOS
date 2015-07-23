//
//  OAIAPHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#if defined(OSMAND_IOS_DEV)

#define kInAppId_Region_Africa @"net.osmand.inapp.region.africa"
#define kInAppId_Region_Russia @"net.osmand.inapp.region.russia"
#define kInAppId_Region_Asia @"net.osmand.inapp.region.asia"
#define kInAppId_Region_Australia @"net.osmand.inapp.region.australia"
#define kInAppId_Region_Europe @"net.osmand.inapp.region.europe"
#define kInAppId_Region_Central_America @"net.osmand.inapp.region.centralamerica"
#define kInAppId_Region_North_America @"net.osmand.inapp.region.northamerica"
#define kInAppId_Region_South_America @"net.osmand.inapp.region.southamerica"

#define kInAppId_Region_All_World @"net.osmand.inapp.region.allworld"

#define kInAppId_Addon_SkiMap @"net.osmand.inapp.addon.skimap"
#define kInAppId_Addon_Nautical @"net.osmand.inapp.addon.nauticalmap"
#define kInAppId_Addon_TrackRecording @"net.osmand.inapp.addon.track_recording"
#define kInAppId_Addon_Parking @"net.osmand.inapp.addon.parking"
#define kInAppId_Addon_Wiki @"net.osmand.inapp.addon.wiki"
#define kInAppId_Addon_Srtm @"net.osmand.inapp.addon.srtm"

#else

#define kInAppId_Region_Africa @"net.osmand.maps.inapp.region.africa"
#define kInAppId_Region_Russia @"net.osmand.maps.inapp.region.russia"
#define kInAppId_Region_Asia @"net.osmand.maps.inapp.region.asia"
#define kInAppId_Region_Australia @"net.osmand.maps.inapp.region.australia"
#define kInAppId_Region_Europe @"net.osmand.maps.inapp.region.europe"
#define kInAppId_Region_Central_America @"net.osmand.maps.inapp.region.centralamerica"
#define kInAppId_Region_North_America @"net.osmand.maps.inapp.region.northamerica"
#define kInAppId_Region_South_America @"net.osmand.maps.inapp.region.southamerica"

#define kInAppId_Region_All_World @"net.osmand.maps.inapp.region.allworld"

#define kInAppId_Addon_SkiMap @"net.osmand.maps.inapp.addon.skimap"
#define kInAppId_Addon_Nautical @"net.osmand.maps.inapp.addon.nautical"
#define kInAppId_Addon_TrackRecording @"net.osmand.maps.inapp.addon.track_recording"
#define kInAppId_Addon_Parking @"net.osmand.maps.inapp.addon.parking"
#define kInAppId_Addon_Wiki @"net.osmand.maps.inapp.addon.wiki"
#define kInAppId_Addon_Srtm @"net.osmand.maps.inapp.addon.srtm"

#endif

#define kId_Addon_TrackRecording_Add_Waypoint @"addon.track_recording.add_waypoint"
#define kId_Addon_Parking_Set @"addon.parking.set"


#define kFreeMapsAvailableTotal 5

UIKIT_EXTERN NSString *const OAIAPProductPurchasedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchaseFailedNotification;
UIKIT_EXTERN NSString *const OAIAPProductsRestoredNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success);

@interface OAFunctionalAddon : NSObject

@property (nonatomic, readonly) NSString *addonId;
@property (nonatomic, readonly) NSString *titleShort;
@property (nonatomic, readonly) NSString *titleWide;
@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, assign) NSInteger sortIndex;
@property (nonatomic, assign) NSInteger tag;

-(instancetype)initWithAddonId:(NSString *)addonId titleShort:(NSString *)titleShort titleWide:(NSString *)titleWide imageName:(NSString *)imageName;

@end

@interface OAProduct : NSObject

@property (nonatomic, readonly) NSString *localizedDescription;
@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSDecimalNumber *price;
@property (nonatomic, readonly) NSLocale *priceLocale;
@property (nonatomic, readonly) NSString *productIdentifier;

@property (nonatomic, readonly) SKProduct *skProductRef;

- (id)initWithSkProduct:(SKProduct *)skProduct;
- (id)initWithTitle:(NSString *)title desc:(NSString *)desc price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale productIdentifier:(NSString *)productIdentifier;
-(id)initWithproductIdentifier:(NSString *)productIdentifier;

- (void)setSkProduct:(SKProduct *)skProduct;

@end

@interface OAIAPHelper : NSObject

+ (OAIAPHelper *)sharedInstance;

@property (nonatomic, readonly) BOOL isAnyMapPurchased;

@property (nonatomic, readonly) NSArray *freePluginsList;
@property (nonatomic, readonly) NSArray *functionalAddons;
@property (nonatomic, readonly) OAFunctionalAddon *singleAddon;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct:(OAProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

- (BOOL)productPurchasedIgnoreDisable:(NSString *)productIdentifier;
- (void)enableProduct:(NSString *)productIdentifier;
- (void)disableProduct:(NSString *)productIdentifier;
- (BOOL)isProductDisabled:(NSString *)productIdentifier;


+(NSArray *)inAppsMaps;
+(NSArray *)inAppsAddons;
+(NSArray *)inAppsAddonsPurchased;

-(OAProduct *)product:(NSString *)productIdentifier;
-(int)productIndex:(NSString *)productIdentifier;
-(BOOL)productsLoaded;

+(int)freeMapsAvailable;
+(void)decreaseFreeMapsCount;

+(NSString *)productIconName:(NSString *)productIdentifier;
+(NSString *)productScreenshotName:(NSString *)productIdentifier;
+(void)showProductAlert:(NSString *)productIdentifier afterPurchase:(BOOL)afterPurchase;

@end
