//
//  OASearchCoreFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASearchCoreAPI.h"

static const int MAX_DEFAULT_SEARCH_RADIUS = 7;

//////////////// CONSTANTS //////////
static const int SEARCH_REGION_API_PRIORITY = 300;
static const int SEARCH_REGION_OBJECT_PRIORITY = 1000;

// context less
static const int SEARCH_LOCATION_PRIORITY = 0;
static const int SEARCH_AMENITY_TYPE_PRIORITY = 100;
static const int SEARCH_AMENITY_TYPE_API_PRIORITY = 100;

// context
static const int SEARCH_STREET_BY_CITY_PRIORITY = 200;
static const int SEARCH_BUILDING_BY_CITY_PRIORITY = 300;
static const int SEARCH_BUILDING_BY_STREET_PRIORITY = 100;
static const int SEARCH_AMENITY_BY_TYPE_PRIORITY = 300;

// context less (slow)
static const int SEARCH_ADDRESS_BY_NAME_API_PRIORITY = 500;
static const int SEARCH_ADDRESS_BY_NAME_API_PRIORITY_RADIUS2 = 500;
static const int SEARCH_ADDRESS_BY_NAME_PRIORITY = 500;
static const int SEARCH_ADDRESS_BY_NAME_PRIORITY_RADIUS2 = 500;

// context less (slower)
static const int SEARCH_AMENITY_BY_NAME_PRIORITY = 700;
static const int SEARCH_AMENITY_BY_NAME_API_PRIORITY_IF_POI_TYPE = 700;
static const int SEARCH_AMENITY_BY_NAME_API_PRIORITY_IF_3_CHAR = 700;

static const double SEARCH_AMENITY_BY_NAME_CITY_PRIORITY_DISTANCE = 0.001;
static const double SEARCH_AMENITY_BY_NAME_TOWN_PRIORITY_DISTANCE = 0.005;

@interface OASearchBaseAPI : OASearchCoreAPI

@end

//@interface OASearchRegionByNameAPI : OASearchBaseAPI
//
//@end

@interface OASearchAddressByNameAPI : OASearchBaseAPI

@end

@interface OASearchAmenityByNameAPI : OASearchBaseAPI

@end

@interface OASearchStreetByCityAPI : OASearchBaseAPI

@end

@interface OASearchBuildingAndIntersectionsByStreetAPI : OASearchBaseAPI

@end

@interface SearchAmenityTypesAPI : OASearchBaseAPI

@end

@interface SearchAmenityByTypeAPI : OASearchBaseAPI

@end

@interface SearchStreetByCityAPI : OASearchBaseAPI

@end

@interface SearchBuildingAndIntersectionsByStreetAPI : OASearchBaseAPI

@end

@interface OASearchCoreFactory : NSObject


@end
