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

#endif


#define kFreeMapsAvailableTotal 5


UIKIT_EXTERN NSString *const OAIAPProductPurchasedNotification;
UIKIT_EXTERN NSString *const OAIAPProductPurchaseFailedNotification;
UIKIT_EXTERN NSString *const OAIAPProductsRestoredNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success);

@interface OAIAPHelper : NSObject

+ (OAIAPHelper *)sharedInstance;

@property (nonatomic, readonly) BOOL isAnyMapPurchased;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

+(NSArray *)inAppsMaps;
+(NSArray *)inAppsAddons;
-(SKProduct *)product:(NSString *)productIdentifier;
-(int)productIndex:(NSString *)productIdentifier;
-(BOOL)productsLoaded;

+(int)freeMapsAvailable;
+(void)decreaseFreeMapsCount;

@end
