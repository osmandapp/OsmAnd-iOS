//
//  OAClickableWayHelper+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAClickableWayHelper.h"

#include <OsmAndCore/Data/ObfMapObject.h>

@interface OAClickableWayHelper(cpp)

- (BOOL) isClickableWay:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(NSDictionary<NSString *, NSString *> *)tags;

- (OAClickableWay *) loadClickableWay:(CLLocation *)selectedLatLon obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(NSDictionary<NSString *, NSString *> *)tags;

@end
