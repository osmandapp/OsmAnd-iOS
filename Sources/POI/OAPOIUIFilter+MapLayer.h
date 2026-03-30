#import "OAPOIUIFilter.h"

#include <OsmAndCore/Data/Amenity.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAPOIUIFilter (MapLayer)

- (BOOL)oa_acceptAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
                    type:(nullable OAPOIType *)type;

@end

NS_ASSUME_NONNULL_END
