//
//  OATransportStop.h
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Data/TransportStop.h>

@class OAPOI;

@interface OATransportStop : NSObject

- (instancetype)initWithStop:(std::shared_ptr<const OsmAnd::TransportStop>)stop;

@property (nonatomic, assign, readonly) std::shared_ptr<const OsmAnd::TransportStop> stop;
@property (nonatomic, readonly) CLLocationCoordinate2D location;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic) OAPOI *poi;
@property (nonatomic) int distance;

@end
