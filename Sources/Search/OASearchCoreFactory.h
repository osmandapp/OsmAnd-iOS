//
//  OASearchCoreFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchCoreFactory.java
//  git revision 5c61cf4c8d3c678f556ad8dba9073bac9c93a6f1

#import <Foundation/Foundation.h>
#import "OASearchCoreAPI.h"

static const int MAX_DEFAULT_SEARCH_RADIUS = 7;

//////////////// CONSTANTS //////////
static const int SEARCH_REGION_API_PRIORITY = 300;
static const int SEARCH_REGION_OBJECT_PRIORITY = 1000;

// context less
static const int SEARCH_LOCATION_PRIORITY = 0;
static const int SEARCH_MAX_PRIORITY = INT_MAX;
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

@class OAObjectType, OAPOIBaseType, OASearchResult;

@interface OASearchBaseAPI : OASearchCoreAPI

- (instancetype) initWithSearchTypes:(NSArray<OAObjectType *> *)searchTypes;

- (BOOL) isSearchAvailable:(OASearchPhrase *)p;
- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher;
- (BOOL) search:(OASearchPhrase *)phrase fullArea:(BOOL)fullArea resultMatcher:(OASearchResultMatcher *)resultMatcher;
- (int) getSearchPriority:(OASearchPhrase *)p;
- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase;

@end

//@interface OASearchRegionByNameAPI : OASearchBaseAPI
//
//@end

@class OASearchStreetByCityAPI, OASearchBuildingAndIntersectionsByStreetAPI, OACustomSearchPoiFilter, OASearchAmenityTypesAPI;

@interface OASearchAddressByNameAPI : OASearchBaseAPI

- (instancetype)initWithCityApi:(OASearchStreetByCityAPI *)cityApi streetsApi:(OASearchBuildingAndIntersectionsByStreetAPI *)streetsApi;

@end

@interface OASearchAmenityByNameAPI : OASearchBaseAPI

@end

@interface OASearchAmenityTypesAPI : OASearchBaseAPI

- (void) clearCustomFilters;
- (void) addCustomFilter:(OACustomSearchPoiFilter *)poiFilter priority:(int)priority;
- (void) setActivePoiFiltersByOrder:(NSArray<NSString *> *)filterOrder;

@end

@interface OASearchAmenityByTypeAPI : OASearchBaseAPI

- (instancetype) initWithTypesAPI:(OASearchAmenityTypesAPI *)typesAPI;

- (OAPOIBaseType *) getUnselectedPoiType;
- (NSString *) getNameFilter;

@end

@interface OASearchStreetByCityAPI : OASearchBaseAPI

- (instancetype) initWithAPI:(OASearchBuildingAndIntersectionsByStreetAPI *) streetsAPI;

@end

@interface OASearchBuildingAndIntersectionsByStreetAPI : OASearchBaseAPI

@end

@interface OASearchLocationAndUrlAPI : OASearchBaseAPI

- (instancetype) initWithAPI:(OASearchAmenityByNameAPI *) amenitiesAPI;
- (void) initCachedOlcCode:(OASearchPhrase *)phrase;

@end


@interface OASearchCoreFactory : NSObject

+ (BOOL) DISPLAY_DEFAULT_POI_TYPES;
+ (void) setDisplayDefaultPoiTypes:(BOOL)value;


@end
