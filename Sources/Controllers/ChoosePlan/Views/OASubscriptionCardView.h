//
//  OASubscriptionCardView.h
//  OsmAnd
//
//  Created by Skalii on 24.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseFeatureCardView.h"

@class OAFeature, OAProduct;

@protocol OAFeatureCardViewDelegate;

@interface OASubscriptionCardView : OABaseFeatureCardView

- (instancetype)initWithSubscription:(OAProduct *)subscription;

@property (nonatomic, weak) id <OAFeatureCardViewDelegate> delegate;

@end
