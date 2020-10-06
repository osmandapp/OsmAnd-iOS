//
//  OARouteImporter.h
//  OsmAnd
//
//  Created by nnngrach on 02.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDocument.h"
#include "routeSegmentResult.h"
#include "routeDataResources.h"

@interface OARouteImporter : NSObject

- (instancetype) initWithFile:(NSString *)file;
- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile;
- (std::vector<std::shared_ptr<RouteSegmentResult>>) importRoute;

@end
