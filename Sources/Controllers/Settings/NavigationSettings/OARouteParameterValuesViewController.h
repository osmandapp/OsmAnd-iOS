//
//  OARouteParameterValuesViewController.h
//  OsmAnd
//
//  Created by Paul on 21.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
struct RoutingParameter;
#endif

@class OALocalRoutingParameterGroup, OALocalRoutingParameter;

@interface OARouteParameterValuesViewController : OABaseSettingsViewController

- (instancetype)initWithRoutingParameterGroup:(OALocalRoutingParameterGroup *)group appMode:(OAApplicationMode *)mode;
- (instancetype)initWithRoutingParameter:(OALocalRoutingParameter *)parameter appMode:(OAApplicationMode *)mode;
#ifdef __cplusplus
- (instancetype)initWithParameter:(RoutingParameter &)parameter appMode:(OAApplicationMode *)mode;
#endif

@end

NS_ASSUME_NONNULL_END
