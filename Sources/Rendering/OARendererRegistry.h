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
#define MARINE_RENDER @"Marine"
#define TOPO_RENDER @"Topo"
#define OSM_CARTO_RENDER @"OSM-carto"
#define OFFROAD_RENDER @"Offroad"
#define LIGHTRS_RENDER @"LightRS"
#define UNIRS_RENDER @"UniRS"
#define DESERT_RENDER @"Desert"
#define SNOWMOBILE_RENDER @"Snowmobile"
#define RENDER_ADDON @".addon.render.xml"

@class OAApplicationMode;

@interface OARendererRegistry : NSObject

+ (NSDictionary<NSString *, NSString *> *)getInternalRenderers;
+ (NSDictionary<NSString *, NSString *> *)getExternalRenderers;

+ (NSArray<NSString *> *)getPathExternalRenderers;

+ (NSDictionary *)getMapStyleInfo:(NSString *)renderer;

@end
