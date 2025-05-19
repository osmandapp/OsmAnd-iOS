//
//  OAPOIHelper+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 04/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/MapObject.h>

NS_ASSUME_NONNULL_BEGIN

@class OASearchPoiTypeFilter, OATopIndexFilter;

@interface OAPOIHelper(cpp)

- (void) setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom;
- (NSArray<OAPOI *> *) findTravelGuidesByKeyword:(NSString *)keyword categoryNames:(NSArray<NSString *> *)categoryNames poiTypeName:(NSString *)typeName currentLocation:(OsmAnd::PointI)location bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish;

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radius:(int)radius;
+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName bboxTopLeft:(CLLocationCoordinate2D)bboxTopLeft bboxBottomRight:(CLLocationCoordinate2D)bboxBottomRight;

+ (void) fetchValuesContentPOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity poi:(OAPOI *)poi;

+ (NSArray<OAPOI *> *) findTravelGuides:(NSArray<NSString *> *)categoryNames currentLocation:(OsmAnd::PointI)currentLocation bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish;

+ (NSArray<OAPOI *> *) findPOI:(OASearchPoiTypeFilter *)searchFilter additionalFilter:(OATopIndexFilter * _Nullable)additionalFilter bbox31:(OsmAnd::AreaI )bbox31 currentLocation:(OsmAnd::PointI)currentLocation includeTravel:(BOOL)includeTravel matcher:(OAResultMatcher<OAPOI *> * _Nullable)matcher publish:(BOOL(^)(OAPOI *poi) _Nullable)publish;

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity;
+ (OAPOIType *) parsePOITypeByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity;

+ (NSString *) processLocalizedNames:(const QHash<QString, QString> &)localizedNames nativeName:(const QString &)nativeName names:(NSMutableDictionary *)names;
+ (void) processDecodedValues:(const QList<OsmAnd::Amenity::DecodedValue> &)decodedValues content:(NSMutableDictionary *)content values:(NSMutableDictionary *)values;

@end

NS_ASSUME_NONNULL_END
