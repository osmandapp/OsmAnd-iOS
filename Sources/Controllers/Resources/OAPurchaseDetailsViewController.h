//
//  OAPurchaseDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAProduct;

typedef NS_ENUM(NSInteger, EOAPurchaseOrigin);

@interface OAPurchaseDetailsViewController : OABaseNavbarViewController

- (instancetype)initWithProduct:(OAProduct *)product origin:(EOAPurchaseOrigin)origin purchaseDate:(NSDate *)purchaseDate expireDate:(NSDate *)expireDate;
- (instancetype)initForCrossplatformSubscription;
- (instancetype)initForFreeStartSubscription;

@end
