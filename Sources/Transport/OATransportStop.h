//
//  OATransportStop.h
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Data/TransportStop.h>

@class OAPOI, OATransportStopAggregated;

@interface OATransportStop : NSObject

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::TransportStop> stop;
@property (nonatomic, readonly) CLLocationCoordinate2D location;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic) OAPOI *poi;
@property (nonatomic) int distance;

@property (nonatomic) OATransportStopAggregated *transportStopAggregated;

@end
