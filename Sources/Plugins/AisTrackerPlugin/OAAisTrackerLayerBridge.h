//
//  OAAisTrackerLayerBridge.h
//  OsmAnd
//
//  Created by OpenAI on 12.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndSharedWrapper.h"

@interface OAAisTrackerLayerBridge : NSObject

+ (void)reloadAisObjects;
+ (void)onAisObjectReceived:(OASAisObject *)object;
+ (void)onAisObjectRemoved:(OASAisObject *)object;

@end
