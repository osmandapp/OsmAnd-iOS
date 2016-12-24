//
//  OAPOIUIFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OACustomSearchPoiFilter.h"

static NSString* const STD_PREFIX = @"std_";
static NSString* const USER_PREFIX = @"user_";
static NSString* const CUSTOM_FILTER_ID = @"user_custom_id";
static NSString* const BY_NAME_FILTER_ID = @"user_by_name";

@class OAPOI, OAPOIBaseType, OAPOICategory;

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

@property (nonatomic, readonly) NSString *filterByName;
@property (nonatomic) NSString *savedFilterByName;
@property (nonatomic, readonly) NSArray<OAPOI *> *currentSearchResult;

@property (nonatomic, readonly) NSArray<NSNumber *> *distanceToSearchValues;

- (instancetype)initWithBasePoiType:(OAPOIBaseType *)type idSuffix:(NSString *)idSuffix;
- (instancetype)initWithName:(NSString *)nm filterId:(NSString *)fId acceptedTypes:(NSDictionary<OAPOICategory *, NSArray<NSString *> *> *)accTypes;
- (instancetype)initWithFiltersToMerge:(NSSet<OAPOIUIFilter *> *)filtersToMerge;

- (BOOL) isAutomaticallyIncreaseSearch;
- (NSArray<OAPOI *> *) searchAmenitiesInternal:(double)lat lon:(double)lon topLatitude:(double)topLatitude bottomLatitude:(double)bottomLatitude leftLongitude:(double)leftLongitude rightLongitude:(double)rightLongitude zoom:(int)zoom matcher:(OAResultMatcher<OAPOI *> *)matcher;

+ (NSComparator) getComparator;

@end
