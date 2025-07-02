//
//  OABaseDetailsObject.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@class OAPOI, OASelectedMapObject, OABaseDetailsObject;

@interface OABaseDetailsObject : NSObject

@property (nonatomic, readonly) NSMutableSet<NSNumber *> *osmIds;
@property (nonatomic, readonly) NSMutableSet<NSString *> *wikidataIds;
@property (nonatomic, readonly) NSMutableArray<OASelectedMapObject *> *selectedObjects;

- (instancetype) initWithObject:(id)object;

- (OAPOI *) getSyntheticAmenity;
- (CLLocationCoordinate2D) getLocation;
- (NSMutableArray<OASelectedMapObject *> *) getSelectedObjects;
- (void) addObject:(id)object;
- (BOOL) overlapsWith:(id)object;
- (void) merge:(OABaseDetailsObject*)other;
- (void) combineData;
- (void) processAmenity:(OAPOI *)amenity contentLocales:(NSSet<NSString *> *)contentLocales;

+ (BOOL) shouldSkip:(id) object;

@end
