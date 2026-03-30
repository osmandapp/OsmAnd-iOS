#import "OAPOIUIFilter+MapLayer.h"
#import "OAAmenityExtendedNameFilter.h"
#import "OAPOI.h"
#import "OAPOIType.h"

@implementation OAPOIUIFilter (MapLayer)

- (BOOL)oa_acceptAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
                    type:(OAPOIType *)type
{
    if (!type || ![self accept:type.category subcategory:type.name])
        return NO;

    const auto values = amenity->getDecodedValuesHash();
    OAAmenityExtendedNameFilter *nameFilter = [self getNameAmenityFilter:self.filterByName];
    if (nameFilter && ![nameFilter acceptAmenity:amenity values:values type:type])
        return NO;

    return values[QString::fromNSString(OSM_DELETE_TAG)] != QString::fromNSString(OSM_DELETE_VALUE);
}

@end
