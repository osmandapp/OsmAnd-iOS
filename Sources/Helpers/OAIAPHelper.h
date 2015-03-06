//
//  OAIAPHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <StoreKit/StoreKit.h>


#define kInAppId_Addon_Nautical @"net.osmand.inapp.addon.nautical"
#define kInAppId_Continent_Africa @"net.osmand.inapp.continent.africa"
#define kInAppId_Continent_Russia @"net.osmand.inapp.continent.russia"
#define kInAppId_Continent_Asia @"net.osmand.inapp.continent.asia"
#define kInAppId_Continent_Australia @"net.osmand.inapp.continent.australia"
#define kInAppId_Continent_Europe @"net.osmand.inapp.continent.europe"
#define kInAppId_Continent_Central_America @"net.osmand.inapp.continent.central_america"
#define kInAppId_Continent_North_America @"net.osmand.inapp.continent.north_america"
#define kInAppId_Continent_South_America @"net.osmand.inapp.continent.south_america"


UIKIT_EXTERN NSString *const OAIAPProductPurchasedNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface OAIAPHelper : NSObject

+ (OAIAPHelper *)sharedInstance;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

@end
