//
//  OASharedAmenitySearcher.h
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPOI, OAMapObject, OASearchPoiTypeFilter, OATopIndexFilter, OAAmenitySearcherRequest;
@class BaseDetailsObject, OASAmenity, OASMapObject, OASAmenitySearcherRequest, OASAmenitySearcherSettings;
@class OAResultMatcher<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

/** Adapts application models and callbacks to the shared amenity search. */
@interface OASharedAmenitySearcher : NSObject

+ (OASAmenitySearcherSettings *)settings;
+ (OASAmenitySearcherRequest *)sharedRequest:(OAAmenitySearcherRequest *)request;
+ (OASAmenity *)sharedAmenity:(OAPOI *)poi;
+ (nullable OASMapObject *)sharedMapObject:(OAMapObject *)object;
+ (nullable BaseDetailsObject *)searchDetailedObject:(id)object;
+ (nullable BaseDetailsObject *)searchDetailedRequest:(OAAmenitySearcherRequest *)request;

+ (NSArray<OAPOI *> *)searchAmenities:(nullable OASearchPoiTypeFilter *)filter
                    additionalFilter:(nullable OATopIndexFilter *)additionalFilter
                         topLatitude:(double)top leftLongitude:(double)left
                      bottomLatitude:(double)bottom rightLongitude:(double)right
                       includeTravel:(BOOL)includeTravel
                             matcher:(nullable OAResultMatcher<OAPOI *> *)matcher
                             publish:(nullable BOOL (^)(OAPOI *))publish;
+ (NSArray<OAPOI *> *)searchByName:(NSString *)name
                     topLatitude:(double)top leftLongitude:(double)left
                  bottomLatitude:(double)bottom rightLongitude:(double)right
                         matcher:(nullable OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *)searchByName:(NSString *)name resourceId:(NSString *)resourceId
                        location:(nullable CLLocation *)location matcher:(nullable OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *)searchOnPath:(NSArray<CLLocation *> *)locations radius:(double)radius
                          filter:(OASearchPoiTypeFilter *)filter matcher:(nullable OAResultMatcher<OAPOI *> *)matcher;
+ (NSArray<OAPOI *> *)mergeAmenities:(NSArray<OAPOI *> *)pois;
+ (NSArray<OAPOI *> *)appAmenities:(NSArray<OASAmenity *> *)amenities;

@end

NS_ASSUME_NONNULL_END
