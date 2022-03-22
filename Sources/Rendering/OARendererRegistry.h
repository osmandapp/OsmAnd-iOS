//
//  OARendererRegistry.h
//  OsmAnd Maps
//
//  Created by Paul on 20.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_RENDER @"OsmAnd"
#define DEFAULT_RENDER_FILE_PATH @"default.render.xml"
#define TOURING_VIEW @"Touring view (contrast and details)"
#define WINTER_SKI_RENDER @"Winter and ski"
#define NAUTICAL_RENDER @"Nautical"
#define TOPO_RENDER @"Topo"
#define MAPNIK_RENDER @"Mapnik"
#define OFFROAD_RENDER @"Offroad"
#define LIGHTRS_RENDER @"LightRS"
#define UNIRS_RENDER @"UniRS"
#define DESERT_RENDER @"Desert"
#define SNOWMOBILE_RENDER @"Snowmobile"

@class OAApplicationMode;

@interface OARendererRegistry : NSObject

+ (NSDictionary<NSString *, NSString *> *)getInternalRenderers;
+ (NSDictionary<NSString *, NSString *> *)getExternalRenderers;

+ (NSArray<NSString *> *)getPathExternalRenderers;

+ (NSDictionary *)getMapStyleInfo:(NSString *)renderer;

@end
