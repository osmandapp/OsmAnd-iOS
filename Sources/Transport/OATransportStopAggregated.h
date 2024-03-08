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

@property (nonatomic) OAPOI *amenity;
@property (nonatomic) NSMutableArray<OATransportStop *> *localTransportStops;
@property (nonatomic) NSMutableArray<OATransportStop *> *nearbyTransportStops;

- (void) addLocalTransportStop:(OATransportStop *)transportStop;
- (void) addNearbyTransportStop:(OATransportStop *)transportStop;

@end
