#if DEBUG
#import "OAMeasurementToolLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAMeasurementToolLayer (UITesting)

+ (nullable NSDictionary<NSString *, id> *)currentRouteStateForUITesting;

@end

NS_ASSUME_NONNULL_END
#endif
