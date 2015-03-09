//
//  OAIAPHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <StoreKit/StoreKit.h>


#define kInAppId_Region_Africa @"net.osmand.inapp.region.africa"
#define kInAppId_Region_Russia @"net.osmand.inapp.region.russia"
#define kInAppId_Region_Asia @"net.osmand.inapp.region.asia"
#define kInAppId_Region_Australia @"net.osmand.inapp.region.australia"
#define kInAppId_Region_Europe @"net.osmand.inapp.region.europe"
#define kInAppId_Region_Central_America @"net.osmand.inapp.region.centralamerica"
#define kInAppId_Region_North_America @"net.osmand.inapp.region.northamerica"
#define kInAppId_Region_South_America @"net.osmand.inapp.region.southamerica"

#define kInAppId_Addon_SkiMap @"net.osmand.inapp.addon.skimap"
#define kInAppId_Addon_Nautical @"net.osmand.inapp.addon.nauticalmap"


UIKIT_EXTERN NSString *const OAIAPProductPurchasedNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success);

@interface OAIAPHelper : NSObject

+ (OAIAPHelper *)sharedInstance;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

+(NSArray *)inAppsMaps;
+(NSArray *)inAppsAddons;
-(SKProduct *)product:(NSString *)productIdentifier;
-(BOOL)productsLoaded;

@end
