//
//  OACurrentStreetName.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//
// OsmAnd/OsmAnd/src/net/osmand/plus/routing/CurrentStreetName.java
// git revision 1873992309cd40ba8f866437113632624b81069c

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OANextDirectionInfo, RoadShield, OARoutingHelper, OASTurnType, OASRouteDataObject;

@interface OACurrentStreetName : NSObject

@property (nonatomic) NSString *text;
@property (nonatomic, nullable) OASTurnType *turnType;
@property (nonatomic, assign) BOOL showMarker; // turn type has priority over showMarker
@property (nonatomic) NSArray<RoadShield *> *shields;
@property (nonatomic) NSString *exitRef;
@property (nonatomic, readonly) BOOL useDestination;

- (instancetype)initWithStreetName:(OANextDirectionInfo *)info;
- (instancetype)initWithStreetName:(OANextDirectionInfo *)info useDestination:(BOOL)useDestination;
- (instancetype)initWithStreetName:(OARoutingHelper *)routingHelper info:(OANextDirectionInfo *)info showNextTurn:(BOOL)showNextTurn;

@end

@interface RoadShield : NSObject

@property (nonatomic, readonly) OASRouteDataObject *rdo;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSString *value;
@property (nonatomic, copy) NSString *additional;

- (instancetype)initWithRDO:(OASRouteDataObject *)rdo tag:(NSString *)tag value:(NSString *)value;
+ (NSArray<RoadShield *> *)createShields:(nullable OASRouteDataObject *)rdo;
+ (NSArray<RoadShield *> *)createDestination:(nullable OASRouteDataObject *)rdo destRef:(NSString *)destRef;

@end

NS_ASSUME_NONNULL_END
