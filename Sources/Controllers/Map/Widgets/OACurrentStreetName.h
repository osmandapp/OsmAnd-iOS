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

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <turnType.h>
#include <binaryRead.h>

NS_ASSUME_NONNULL_BEGIN

@class OANextDirectionInfo, RoadShield, OARoutingHelper;

@interface OACurrentStreetName : NSObject

@property (nonatomic) NSString *text;
@property (nonatomic) std::shared_ptr<TurnType> turnType;
@property (nonatomic, assign) BOOL showMarker; // turn type has priority over showMarker
@property (nonatomic) NSArray<RoadShield *> *shields;
@property (nonatomic) NSString *exitRef;
@property (nonatomic, readonly) BOOL useDestination;

- (instancetype)initWithStreetName:(OANextDirectionInfo *)info;
- (instancetype)initWithStreetName:(OANextDirectionInfo *)info useDestination:(BOOL)useDestination;
- (instancetype)initWithStreetName:(OARoutingHelper *)routingHelper info:(OANextDirectionInfo *)info showNextTurn:(BOOL)showNextTurn;

@end

@interface RoadShield : NSObject

@property (nonatomic, readonly) std::shared_ptr<RouteDataObject> rdo;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSString *value;
@property (nonatomic, copy) NSString *additional;

- (instancetype)initWithRDO:(std::shared_ptr<RouteDataObject>)rdo tag:(NSString *)tag value:(NSString *)value;
+ (NSArray<RoadShield *> *)createShields:(std::shared_ptr<RouteDataObject>)rdo;
+ (NSArray<RoadShield *> *)createDestination:(std::shared_ptr<RouteDataObject>)rdo destRef:(NSString *)destRef;

@end

NS_ASSUME_NONNULL_END
