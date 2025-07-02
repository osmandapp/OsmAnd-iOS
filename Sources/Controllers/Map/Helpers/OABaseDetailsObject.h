//
//  OABaseDetailsObject.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAContextMenuProvider.h"

NS_ASSUME_NONNULL_BEGIN


@class OAPOI, OASelectedMapObject, OABaseDetailsObject, OATransportStop, OARenderedObject;

@interface OABaseDetailsObject : NSObject

@property (nonatomic, readonly) NSMutableSet<NSNumber *> *osmIds;
@property (nonatomic, readonly) NSMutableSet<NSString *> *wikidataIds;
@property (nonatomic, readonly) NSMutableArray<id> *objects;
@property (nonatomic, readonly) NSString *lang;

- (instancetype) initWithLang:(NSString *)lang;
- (instancetype) initWithObject:(id)object lang:(NSString *)lang;
- (instancetype) initWithAmenities:(NSArray<OAPOI *> *)amenities lang:(NSString *)lang;

- (OAPOI *) getSyntheticAmenity;
- (CLLocation *) getLocation;
- (NSMutableArray<id> *) getObjects;

- (BOOL) isObjectFull;
- (BOOL) isObjectEmpty;

- (BOOL) addObject:(id)object;

- (BOOL) overlapsWith:(id)object;
- (void) merge:(id)object;
- (void) combineData;
- (void) processAmenity:(OAPOI *)amenity contentLocales:(NSMutableSet<NSString *> *)contentLocales;

- (void) setObfResourceName:(NSString *)obfName;

- (void) setX:(NSMutableArray<NSNumber *> *)x;
- (void) setY:(NSMutableArray<NSNumber *> *)y;
- (void) addX:(NSNumber *)x;
- (void) addY:(NSNumber *)y;

- (NSArray<OAPOI *> *) getAmenities;
- (NSArray<OATransportStop *> *) getTransportStops;
- (NSArray<OARenderedObject *> *) getRenderedObjects;

@end


NS_ASSUME_NONNULL_END
