//
//  OARouteParameterValuesViewController.h
//  OsmAnd
//
//  Created by Paul on 21.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

NS_ASSUME_NONNULL_BEGIN

struct RoutingParameter;

@class OALocalRoutingParameterGroup, OALocalRoutingParameter;

@interface OARouteParameterValuesViewController : OABaseSettingsViewController

- (instancetype)initWithRoutingParameterGroup:(OALocalRoutingParameterGroup *)group appMode:(OAApplicationMode *)mode;
- (instancetype)initWithRoutingParameter:(OALocalRoutingParameter *)parameter appMode:(OAApplicationMode *)mode;
- (instancetype)initWithParameter:(RoutingParameter &)parameter appMode:(OAApplicationMode *)mode;

@end

NS_ASSUME_NONNULL_END
