//
//  OAPOILayerTopPlacesProvider.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <QList>

@class QuadRect;

typedef BOOL(^OATopPlacesAmenitiesProvider)(QuadRect *latLonBounds, id matcher, QList<std::shared_ptr<const OsmAnd::Amenity>> *amenities);

NS_ASSUME_NONNULL_BEGIN

@interface OAPOILayerTopPlacesProvider : NSObject

@property (nonatomic, copy, nullable) OATopPlacesAmenitiesProvider cachedAmenitiesProvider;

- (void)setEnabled:(BOOL)enabled;
- (void)setTextScale:(CGFloat)textScale;
- (void)refreshVisiblePlaces;
- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc;
- (void)resetLayer;

- (QList<std::shared_ptr<const OsmAnd::Amenity>>)displayedAmenities;
- (QList<std::shared_ptr<const OsmAnd::Amenity>>)topPlaces;
- (void)updateSelectedTopPlaceId:(nullable NSNumber *)placeId;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTopPlaceBaseOrder:(int)baseOrder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
