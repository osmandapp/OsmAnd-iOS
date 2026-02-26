//
//  OAPOILayerTopPlacesProvider.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#include <OsmAndCore/Utilities.h>

@class OAPOI, MapSelectionResult;

NS_ASSUME_NONNULL_BEGIN

@interface OAPOILayerTopPlacesProvider : NSObject

@property (nonatomic, strong, readonly, nullable) NSDictionary<NSNumber *, OAPOI *> *topPlaces;

- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc;
- (void)updateLayer;
- (void)resetLayer;

- (void)resetSelectedTopPlaceIfNeeded;
- (NSArray<OAPOI *> *)displayedAmenities;
- (void)contextMenuDidShow:(id)targetObj;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTopPlaceBaseOrder:(int)baseOrder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

