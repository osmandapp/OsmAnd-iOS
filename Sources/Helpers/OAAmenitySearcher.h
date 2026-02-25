//
//  OAAmenitySearcher.h
//  OsmAnd
//
//  Created by Max Kojin on 08/08/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAPOIHelper.h"

NS_ASSUME_NONNULL_BEGIN


@class OAMapObject, BaseDetailsObject;

@interface OAAmenitySearcherRequest : NSObject

@property (nonatomic, strong, nullable) CLLocation *latLon;
@property (nonatomic, assign) int64_t osmId;
@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, copy, nullable) NSString *wikidata;
@property (nonatomic, strong) NSMutableArray<NSString *> *names;
@property (nonatomic, nullable) NSMutableDictionary<NSString *, NSString *>* tags;
@property (nonatomic, copy, nullable) NSString *mainAmenityType;

- (instancetype)initWithMapObject:(OAMapObject *)mapObject;
- (instancetype)initWithMapObject:(OAMapObject *)mapObject names:(NSArray<NSString *> *)names;

@end


@interface OAAmenitySearcher : NSObject

@property (weak, nonatomic) id<OAPOISearchDelegate> delegate;

+ (OAAmenitySearcher *) sharedInstance;

- (nullable BaseDetailsObject *)searchDetailedObject:(id)object;
- (nullable BaseDetailsObject *)searchDetailedObjectWithRequest:(OAAmenitySearcherRequest *)request;

- (NSArray<NSString *> *) getAmenityRepositories:(BOOL)includeTravel;

- (BOOL) breakSearch;
- (void) findPOIsByKeyword:(NSString *)keyword;
- (void) findPOIsByKeyword:(NSString *)keyword categoryName:(nullable NSString *)category poiTypeName:(nullable NSString *)type radiusIndex:(int *)radiusIndex;
- (void) findPOIsByFilter:(OAPOIUIFilter *)filter radiusIndex:(int *)radiusIndex;
+ (NSArray<OAPOI *> *) findPOIsByFilter:(OASearchPoiTypeFilter *)filter topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *) findPOIsByName:(NSString *)query topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *) searchPOIsOnThePath:(NSArray<CLLocation *> *)locations radius:(double)radius filter:(OASearchPoiTypeFilter *)filter matcher:(OAResultMatcher<OAPOI *> *)matcher;
+ (OAPOI *) findPOIByOsmId:(uint64_t)osmId lat:(double)lat lon:(double)lon;
+ (OAPOI *) findPOIByName:(NSString *)name lat:(double)lat lon:(double)lon;
+ (OAPOI *) findPOIByOriginName:(NSString *)originName lat:(double)lat lon:(double)lon;
+ (NSArray<OAPOI *> *) findPOI:(OASearchPoiTypeFilter *)searchFilter additionalFilter:(nullable OATopIndexFilter *)additionalFilter lat:(double)lat lon:(double)lon radius:(int)radius includeTravel:(BOOL)includeTravel matcher:(nullable OAResultMatcher<OAPOI *> *)matcher publish:(nullable BOOL(^)(OAPOI *poi))publish;

+ (NSArray<OAPOI *> *)searchAmenities:(OASearchPoiTypeFilter *)searchFilter
                     additionalFilter:(OATopIndexFilter *)additionalFilter
                          topLatitude:(double)topLatitude
                       bottomLatitude:(double)bottomLatitude
                        leftLongitude:(double)leftLongitude
                       rightLongitude:(double)rightLongitude
                        includeTravel:(BOOL)includeTravel
                              matcher:(OAResultMatcher<OAPOI *> *)matcher
                              publish:(BOOL(^)(OAPOI *poi))publish;

+ (NSArray<OAPOI *> *)filterUniqueAmenitiesByOsmIdOrWikidata:(NSArray<OAPOI *> *)amenities;

@end


NS_ASSUME_NONNULL_END
