//
//  OAPOIUIFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

#import <Foundation/Foundation.h>
#import "OACustomSearchPoiFilter.h"
#import <CoreLocation/CoreLocation.h>

#define INVALID_ORDER -1

static NSString* const STD_PREFIX = @"std_";
static NSString* const USER_PREFIX = @"user_";
static NSString* const CUSTOM_FILTER_ID = @"user_custom_id";
static NSString* const BY_NAME_FILTER_ID = @"user_by_name";

@class OAPOI, OAPOIBaseType, OAPOIType, OAPOICategory;

@interface OAAmenityNameFilter : NSObject

typedef BOOL(^OAAmenityNameFilterAccept)(OAPOI * poi);
@property (nonatomic, strong) OAAmenityNameFilterAccept acceptFunction;

- (BOOL) accept:(OAPOI *)a;

- (instancetype)initWithAcceptFunc:(OAAmenityNameFilterAccept)aFunction;

@end

@interface OAPOIUIFilter : OACustomSearchPoiFilter

@property (nonatomic, readonly) NSString *filterId;
@property (nonatomic, readonly) NSString *standardIconId;
@property (nonatomic, readonly) NSString *name;
@property (assign) BOOL isStandardFilter;

@property (readonly) int distanceInd;
@property (nonatomic) int order;
@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL isDeleted;

@property (nonatomic) NSString *filterByName;
@property (nonatomic) NSString *savedFilterByName;
@property (nonatomic, readonly) NSArray<OAPOI *> *currentSearchResult;
@property (nonatomic, readonly) OAPOIBaseType *baseType;
@property (nonatomic, readonly) NSArray<NSNumber *> *distanceToSearchValues;

- (instancetype) initWithBasePoiType:(OAPOIBaseType *)type idSuffix:(NSString *)idSuffix;
- (instancetype) initWithName:(NSString *)nm filterId:(NSString *)fId acceptedTypes:(NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *)accTypes;
- (instancetype) initWithFiltersToMerge:(NSSet<OAPOIUIFilter *> *)filtersToMerge;
- (instancetype) initWithFilter:(OAPOIUIFilter *)filter name:(NSString *)nm filterId:(NSString *)fId;

- (BOOL) isAutomaticallyIncreaseSearch;
- (NSArray<OAPOI *> *) searchAmenitiesInternal:(double)lat lon:(double)lon topLatitude:(double)topLatitude bottomLatitude:(double)bottomLatitude leftLongitude:(double)leftLongitude rightLongitude:(double)rightLongitude zoom:(int)zoom matcher:(OAResultMatcher<OAPOI *> *)matcher;

+ (NSComparator) getComparator;

+ (UIImage *) getUserIcon;

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypes;

- (void) setFilterByName:(NSString *)filter;
- (void) updateFilterResults;
- (NSArray<OAPOI *> *) searchAgain:(double)lat lon:(double)lon;
- (NSArray<OAPOI *> *) searchFurther:(double)latitude longitude:(double)longitude matcher:(OAResultMatcher<OAPOI *> *)matcher;
- (BOOL) isSearchFurtherAvailable;
- (NSString *) getSearchArea:(BOOL)next;
- (void) clearPreviousZoom;
- (void) clearCurrentResults;
- (NSArray<OAPOI *> *) initializeNewSearch:(double)lat lon:(double)lon firstTimeLimit:(int)firstTimeLimit  matcher:(OAResultMatcher<OAPOI *> *)matcher;
- (NSArray<OAPOI *> *) searchAmenities:(double)top left:(double)left bottom:(double)bottom right:(double)right zoom:(int)zoom matcher:(OAResultMatcher<OAPOI *> *)matcher;
- (OAAmenityNameFilter *) getNameFilter:(NSString *)filter;
- (NSString *) getNameToken24H;
- (NSString *) getNameTokenOpen;
- (NSObject *) getIconResource;
- (OAResultMatcher<OAPOI *> *)wrapResultMatcher:(OAResultMatcher<OAPOI *> *)matcher;
- (NSString *) getName;
- (NSString *) getGeneratedName:(int)chars;
- (NSSet<NSString *> *) getAcceptedSubtypes:(OAPOICategory *)type;
- (BOOL) isTypeAccepted:(OAPOICategory *)t;
- (void) clearFilter;
- (BOOL) areAllTypesAccepted;
- (void) updateTypesToAccept:(OAPOIBaseType *)pt;
- (void) combineWithPoiFilter:(OAPOIUIFilter *)f;
- (void) combineWithPoiFilters:(NSSet<OAPOIUIFilter *> *)filters;
+ (void) combineStandardPoiFilters:(NSMutableSet<OAPOIUIFilter *> *)filters;
- (void) replaceWithPoiFilter:(OAPOIUIFilter *)f;
- (int) getAcceptedTypesCount;
- (void) selectSubTypesToAccept:(OAPOICategory *)t accept:(NSMutableSet<NSString *> *)accept;
- (void) setTypeToAccept:(OAPOICategory *)poiCategory b:(BOOL)b;
- (NSDictionary<NSString *, OAPOIType *> *) getPoiAdditionals;
- (NSString *) getIconId;
- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory;
- (BOOL) isEmpty;
- (NSArray<OAPOI *> *) searchAmenitiesOnThePath:(NSArray<CLLocation *> *)locs poiSearchDeviationRadius:(int)poiSearchDeviationRadius;
- (void) removeUnsavedFilterByName;

@end
