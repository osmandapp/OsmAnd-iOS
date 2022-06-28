//
//  OAPurchaseDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAProduct;

@interface OAPurchaseDetailsViewController : OACompoundViewController

- (instancetype)initWithProduct:(OAProduct *)product;
- (instancetype)initForCrossplatformSubscription;

@end
