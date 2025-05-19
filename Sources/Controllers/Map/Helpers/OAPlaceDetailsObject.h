//
//  OAPlaceDetailsObject.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAContextMenuProvider.h"

@class OAPOI, OASelectedMapObject, OAPlaceDetailsObject;

@interface OAPlaceDetailsObject : NSObject

@property (nonatomic, readonly) NSMutableSet<NSNumber *> *osmIds;
@property (nonatomic, readonly) NSMutableSet<NSString *> *wikidataIds;
@property (nonatomic, readonly) NSMutableArray<OASelectedMapObject *> *selectedObjects;

- (instancetype) initWithObject:(id<OAContextMenuProvider>)object provider:(id<OAContextMenuProvider>)provider;

- (OAPOI *) getSyntheticAmenity;
- (CLLocationCoordinate2D) getLocation;
- (NSMutableArray<OASelectedMapObject *> *) getSelectedObjects;
- (void) addObject:(id)object provider:(id<OAContextMenuProvider>)provider;
- (BOOL) overlapsWith:(id)object;
- (void) merge:(OAPlaceDetailsObject*)other;
- (void) combineData;
- (void) processAmenity:(OAPOI *)amenity contentLocales:(NSMutableSet<NSString *> *)contentLocales;

+ (BOOL) shouldSkip:(id) object;

@end
