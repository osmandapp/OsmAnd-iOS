//
//  OARouteKey+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 04/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OARouteKey.h"

#import <OsmAndCore/NetworkRouteContext.h>


@interface OARouteKey(cpp)

@property (nonatomic, readonly) OsmAnd::NetworkRouteKey routeKey;

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key;

@end
