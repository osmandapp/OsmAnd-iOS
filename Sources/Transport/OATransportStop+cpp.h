//
//  OATransportStop+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 03/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//
#import "OATransportStop.h"
#import "OAMapObject+cpp.h"

#include <OsmAndCore/Data/TransportStop.h>

@interface OATransportStop(cpp)

- (instancetype)initWithStop:(std::shared_ptr<const OsmAnd::TransportStop>)stop;
- (std::shared_ptr<const OsmAnd::TransportStop>)getStopObject;

@end
