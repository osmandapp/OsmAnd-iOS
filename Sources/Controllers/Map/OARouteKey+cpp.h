//
//  OARouteKey+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 04/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OARouteKey.h"

#include  <OsmAndCore/NetworkRouteContext.h>


@interface OARouteKey(cpp)

@property (nonatomic, readonly) OsmAnd::NetworkRouteKey routeKey;
@property (nonatomic, readonly) OsmAnd::OsmRouteType type;

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key;
- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key type:(const OsmAnd::OsmRouteType *)type;

@end
