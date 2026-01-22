//
//  OAAmenitySearcher+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 09/08/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/MapObject.h>

#import "OrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

@class OASearchPoiTypeFilter, OATopIndexFilter;


@interface OAAmenitySearcher(cpp)

- (void) setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom;

+ (NSArray<OAPOI *> *) findPOIsByTagName:(nullable NSString *)tagName name:(nullable NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(nullable NSString *)typeName radius:(int)radius;
+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName bboxTopLeft:(CLLocationCoordinate2D)bboxTopLeft bboxBottomRight:(CLLocationCoordinate2D)bboxBottomRight;
+ (NSArray<OAPOI *> *) findPOI:(OASearchPoiTypeFilter *)searchFilter additionalFilter:(OATopIndexFilter * _Nullable)additionalFilter bbox31:(OsmAnd::AreaI )bbox31 currentLocation:(OsmAnd::PointI)currentLocation includeTravel:(BOOL)includeTravel matcher:(OAResultMatcher<OAPOI *> * _Nullable)matcher publish:(BOOL(^)(OAPOI *poi) _Nullable)publish;

+ (NSArray<OAPOI *> *) findTravelGuides:(NSArray<NSString *> *)categoryNames currentLocation:(OsmAnd::PointI)currentLocation bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish;
- (NSArray<OAPOI *> *) findTravelGuidesByKeyword:(NSString *)keyword categoryNames:(NSArray<NSString *> *)categoryNames poiTypeName:(NSString * _Nullable)typeName currentLocation:(OsmAnd::PointI)location bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish;

+ (nullable OAPOI *)parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity;
+ (OAPOIType *) parsePOITypeByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity;
+ (NSArray<OAPOI *> *)findPOI:(OASearchPoiTypeFilter *)searchFilter
             additionalFilter:(OATopIndexFilter *)additionalFilter
                       bbox31:(OsmAnd::AreaI)bbox31
              currentLocation:(OsmAnd::PointI)currentLocation
                includeTravel:(BOOL)includeTravel
              skipAcceptCheck:(BOOL)skipAcceptCheck
                      matcher:(OAResultMatcher<OAPOI *> *)matcher
                      publish:(BOOL(^)(OAPOI *poi))publish;

@end

NS_ASSUME_NONNULL_END
