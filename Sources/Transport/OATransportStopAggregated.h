//
//  OATransportStopAggregated.h
//  OsmAnd
//
//  Created by Max Kojin on 08/03/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OAPOI, OATransportStop;

@interface OATransportStopAggregated : NSObject

@property (nonatomic, nullable) OAPOI *amenity;
@property (nonatomic) NSMutableArray<OATransportStop *> *localTransportStops;
@property (nonatomic) NSMutableArray<OATransportStop *> *nearbyTransportStops;

- (void) addLocalTransportStop:(OATransportStop *)transportStop;
- (void) addNearbyTransportStop:(OATransportStop *)transportStop;

@end

NS_ASSUME_NONNULL_END
