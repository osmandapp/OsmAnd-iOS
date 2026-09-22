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
#include <OsmAndCore/Data/TransportRoute.h>

@interface OATransportStop(cpp)

- (instancetype)initWithStop:(std::shared_ptr<const OsmAnd::TransportStop>)stop;
- (std::shared_ptr<const OsmAnd::TransportStop>)getStopObject;

// Routes merged from every obf that holds a copy of this stop, empty when it was not searched for
- (const QList<std::shared_ptr<const OsmAnd::TransportRoute>> &)getRoutes;
- (void)setRoutes:(const QList<std::shared_ptr<const OsmAnd::TransportRoute>> &)routes;

@end
