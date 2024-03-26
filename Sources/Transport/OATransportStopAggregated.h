//
//  OATransportStopAggregated.h
//  OsmAnd
//
//  Created by Max Kojin on 08/03/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPOI, OATransportStop;


@interface OATransportStopAggregated : NSObject

@property (nonatomic, nullable) OAPOI *amenity;
@property (nonatomic, nonnull) NSMutableArray<OATransportStop *> *localTransportStops;
@property (nonatomic, nonnull) NSMutableArray<OATransportStop *> *nearbyTransportStops;

- (void) addLocalTransportStop:(nonnull OATransportStop *)transportStop;
- (void) addNearbyTransportStop:(nonnull OATransportStop *)transportStop;

@end
