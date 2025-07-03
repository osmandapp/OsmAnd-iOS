//
//  OATransportStop.h
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class OAPOI, OATransportStopAggregated;

@interface OATransportStop : NSObject

@property (nonatomic, readonly) CLLocationCoordinate2D location;
@property (nonatomic, readonly, nullable) NSString *name;

@property (nonatomic, nullable) OAPOI *poi;
@property (nonatomic) int distance;

@property (nonatomic, nullable) OATransportStopAggregated *transportStopAggregated;

@end
