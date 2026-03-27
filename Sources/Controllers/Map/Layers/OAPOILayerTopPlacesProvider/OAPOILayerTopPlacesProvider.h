//
//  OAPOILayerTopPlacesProvider.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#include <OsmAndCore/Utilities.h>

@class OAPOI, MapSelectionResult, QuadRect;

typedef NSArray<OAPOI *> * _Nullable (^OATopPlacesAmenitiesProvider)(QuadRect *latLonBounds, id matcher);

NS_ASSUME_NONNULL_BEGIN

@interface OAPOILayerTopPlacesProvider : NSObject

@property (nonatomic, strong, readonly, nullable) NSDictionary<NSNumber *, OAPOI *> *topPlaces;
@property (nonatomic, copy, nullable) OATopPlacesAmenitiesProvider cachedAmenitiesProvider;

- (void)setEnabled:(BOOL)enabled;
- (void)setTextScale:(CGFloat)textScale;
- (void)refreshVisiblePlaces;
- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc;
- (void)resetLayer;

- (void)resetSelectedTopPlaceIfNeeded;
- (NSArray<OAPOI *> *)displayedAmenities;
- (void)contextMenuDidShow:(id)targetObj;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTopPlaceBaseOrder:(int)baseOrder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
