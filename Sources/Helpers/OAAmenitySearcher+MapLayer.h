#import "OAAmenitySearcher.h"

NS_ASSUME_NONNULL_BEGIN

@class OAPOIMapLayerItem, OAPOIUIFilter;

@interface OAAmenitySearcher (MapLayer)

+ (NSArray<OAPOIMapLayerItem *> *)searchMapLayerOfflineItems:(OAPOIUIFilter *)filter
                                                 topLatitude:(double)topLatitude
                                              bottomLatitude:(double)bottomLatitude
                                               leftLongitude:(double)leftLongitude
                                              rightLongitude:(double)rightLongitude
                                                        zoom:(NSInteger)zoom
                                            maxAcceptedCount:(NSUInteger)maxAcceptedCount
                                               includeTravel:(BOOL)includeTravel
                                                 interrupted:(BOOL(^ _Nullable)(void))interrupted;

@end

NS_ASSUME_NONNULL_END
