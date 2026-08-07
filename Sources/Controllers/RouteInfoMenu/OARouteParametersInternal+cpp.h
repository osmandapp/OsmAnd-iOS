#import "OARoutePreferencesParameters.h"
#import "OARouteParameterValuesViewController.h"

struct RoutingParameter;

@interface OALocalRoutingParameter (cpp)

@property struct RoutingParameter routingParameter;

@end

@interface OALocalRoutingParameterGroup (cpp)

- (void)addRoutingParameter:(RoutingParameter)routingParameter;

@end

NS_ASSUME_NONNULL_BEGIN

@interface OARouteParameterValuesViewController (cpp)

- (instancetype)initWithParameter:(RoutingParameter &)parameter appMode:(OAApplicationMode *)mode;

@end

NS_ASSUME_NONNULL_END
