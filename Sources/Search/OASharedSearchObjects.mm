//
//  OASharedSearchObjects.mm
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASharedSearchObjects.h"
#import "OACity.h"
#import "OAStreet.h"
#import "OABuilding.h"
#import "OAAmenitySearcher.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OATopIndexFilter.h"
#import "OsmAndSharedWrapper.h"

#import <CoreLocation/CoreLocation.h>

@implementation OASharedSearchObjects

+ (nullable id)appObjectFor:(nullable id)sharedObject
{
    if ([sharedObject isKindOfClass:OASCity.class])
        return [[OACity alloc] initWithSharedCity:sharedObject];
    if ([sharedObject isKindOfClass:OASStreet.class])
        return [[OAStreet alloc] initWithSharedStreet:sharedObject];
    if ([sharedObject isKindOfClass:OASBuilding.class])
        return [[OABuilding alloc] initWithSharedBuilding:sharedObject];
    if ([sharedObject isKindOfClass:OASAmenity.class])
        return [OAAmenitySearcher parsePOIBySharedAmenity:sharedObject];
    if ([sharedObject isKindOfClass:OASAbstractPoiType.class])
        return [self poiType:sharedObject];
    if ([sharedObject isKindOfClass:OASTopIndexFilter.class])
    {
        OASTopIndexFilter *filter = sharedObject;
        NSString *poiSubType = [OASMapPoiTypes.companion.TOP_INDEX_ADDITIONAL_PREFIX stringByAppendingString:[filter getTag]];
        return [[OATopIndexFilter alloc] initWithPoiSubType:poiSubType value:[filter getValue]];
    }
    if ([sharedObject isKindOfClass:OASKLatLon.class])
    {
        OASKLatLon *latLon = sharedObject;
        return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
    return sharedObject;
}

// the app's poi type of the same key: a category, a filter of one, an additional type or a type
+ (nullable OAPOIBaseType *)poiType:(OASAbstractPoiType *)type
{
    OAPOIHelper *helper = OAPOIHelper.sharedInstance;
    NSString *key = [type getKeyName];
    if ([type isKindOfClass:OASPoiCategory.class])
        return [helper getPoiCategoryByName:key];
    if ([type isKindOfClass:OASPoiFilter.class])
    {
        for (OAPOICategory *category in [helper getCategories:YES])
        {
            for (OAPOIFilter *filter in category.poiFilters)
            {
                if ([filter.name isEqualToString:key])
                    return filter;
            }
        }
        return nil;
    }
    if ([type isAdditional])
        return [helper getAnyPoiAdditionalTypeByKey:key];
    return [helper getPoiTypeByKey:key];
}

@end
