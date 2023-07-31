//
//  OAPurchaseDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAProduct;

@interface OAPurchaseDetailsViewController : OABaseNavbarViewController

- (instancetype)initWithProduct:(OAProduct *)product;
- (instancetype)initForCrossplatformSubscription;
- (instancetype)initForFreeStartSubscription;

@end
