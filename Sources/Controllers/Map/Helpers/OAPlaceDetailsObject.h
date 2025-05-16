//
//  OAPlaceDetailsObject.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@class OAPOI, OASelectedMapObject, OAPlaceDetailsObject;

@interface OAPlaceDetailsObject : NSObject

@property (nonatomic, readonly) NSMutableSet<NSNumber *> *osmIds;
@property (nonatomic, readonly) NSMutableSet<NSString *> *wikidataIds;
@property (nonatomic, readonly) NSMutableArray<OASelectedMapObject *> *selectedObjects;

- (instancetype) initWithObject:(id)object;

- (OAPOI *) getSyntheticAmenity;
- (CLLocationCoordinate2D) getLocation;
- (NSMutableArray<OASelectedMapObject *> *) getSelectedObjects;
- (void) addObject:(id)object provider:(id)provider;
- (BOOL) overlapsWith:(id)object;
- (void) merge:(OAPlaceDetailsObject*)other;
- (void) combineData;
- (void) processAmenity:(OAPOI *)amenity contentLocales:(NSMutableSet<NSString *> *)contentLocales;

+ (BOOL) shouldSkip:(id) object;

@end
