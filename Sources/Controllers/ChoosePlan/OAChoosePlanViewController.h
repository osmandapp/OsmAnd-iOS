//
//  OAChoosePlanViewController.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef NS_ENUM (NSUInteger, OAChoosePlanViewControllerType)
{
    EOAChoosePlan = 0,
    EOAChooseSubscription
};

NS_ASSUME_NONNULL_BEGIN

@protocol OAChoosePlanDelegate

- (void)onProductNotification;

@end

@class OAFeature, OAProduct;

@interface OAChoosePlanViewController : OASuperViewController

- (instancetype) initWithFeature:(OAFeature *)feature;
- (instancetype) initWithProduct:(OAProduct *)product type:(OAChoosePlanViewControllerType)type;

@property (nonatomic, weak) id<OAChoosePlanDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
