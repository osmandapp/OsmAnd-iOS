//
//  OARouteDirectionInfo+cpp.h
//  OsmAnd
//
//  Created by Skalii on 01.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteDirectionInfo.h"

#include <binaryRead.h>
#include <turnType.h>

@interface OARouteDirectionInfo(cpp)

// Type of action to take
@property (nonatomic, assign) std::shared_ptr<TurnType> turnType;

@property (nonatomic) std::shared_ptr<RouteDataObject> routeDataObject;

- (instancetype)initWithAverageSpeed:(float)averageSpeed turnType:(std::shared_ptr<TurnType>)turnType;

@end
