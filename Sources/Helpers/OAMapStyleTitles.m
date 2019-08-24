//
//  OAMapStyleTitles.m
//  OsmAnd
//
//  Created by Paul on 8/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapStyleTitles.h"

static NSDictionary<NSString *, NSString *> *stylesTitlesOffline;

@implementation OAMapStyleTitles

+ (NSDictionary<NSString *, NSString *> *)getMapStyleTitles
{
    if (!stylesTitlesOffline)
    {
        stylesTitlesOffline = @{
                                @"default" : @"OsmAnd",
                                @"nautical" : @"Nautical",
                                @"Ski-map" : @"Ski map",
                                @"UniRS" : @"UniRS",
                                @"Touring-view_(more-contrast-and-details).render" : @"Touring view",
                                @"LightRS" : @"LightRS",
                                @"Topo" : @"Topo",
                                @"Offroad by ZLZK" : @"Offroad",
                                @"Depends-template" : @"Mapnik"
                                };
    }
    return stylesTitlesOffline;
}

@end
