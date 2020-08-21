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

@class OALocalRoutingParameterGroup;

@interface OARouteParameterValuesViewController : OABaseSettingsViewController

- (instancetype) initWithRoutingParameter:(RoutingParameter &)parameter appMode:(OAApplicationMode *)mode;
- (instancetype) initWithRoutingParameterGroup:(OALocalRoutingParameterGroup *)group appMode:(OAApplicationMode *)mode;

@end

NS_ASSUME_NONNULL_END
