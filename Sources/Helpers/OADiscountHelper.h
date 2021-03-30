//
//  OADiscountHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAIAPHelper.h"

@protocol OACondition <NSObject>

- (NSString *) getId;
- (BOOL) matches:(NSString *)value;

@end

@interface OAPurchaseCondition : NSObject<OACondition>

@property (nonatomic) OAIAPHelper *helper;

- (instancetype) initWithIAPHelper:(OAIAPHelper *)helper;

@end

@interface OANotPurchasedSubscriptionCondition : OAPurchaseCondition

@end

@interface OAPurchasedSubscriptionCondition : OAPurchaseCondition

@end

@interface OANotPurchasedInAppPurchaseCondition : OAPurchaseCondition

@end

@interface OAPurchasedInAppPurchaseCondition : OAPurchaseCondition

@end

@interface OANotPurchasedPluginCondition : OAPurchaseCondition

@end

@interface OAPurchasedPluginCondition : OAPurchaseCondition

@end

@interface OADiscountHelper : NSObject

+ (OADiscountHelper *)instance;

- (void) checkAndDisplay;
- (BOOL) isVisible;

@end
