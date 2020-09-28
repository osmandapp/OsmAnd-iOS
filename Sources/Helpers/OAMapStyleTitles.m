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
                                @"Ski-map" : @"Winter and ski",
                                @"UniRS" : @"UniRS",
                                @"Touring-view_(more-contrast-and-details).render" : @"Touring view",
                                @"LightRS" : @"LightRS",
                                @"Topo" : @"Topo",
                                @"Offroad by ZLZK" : @"Offroad",
                                @"Depends-template" : @"Mapnik",
                                @"desert" : @"Desert"
                                };
    }
    return stylesTitlesOffline;
}

+ (int) getSortIndexForTitle:(NSString *)title
{
    if ([title isEqualToString:@"default"])
        return 0;
    else if ([title isEqualToString:@"UniRS"])
        return 1;
    else if ([title isEqualToString:@"Touring-view_(more-contrast-and-details).render"])
        return 2;
    else if ([title isEqualToString:@"LightRS"])
        return 3;
    else if ([title isEqualToString:@"Ski-map"])
        return 4;
    else if ([title isEqualToString:@"nautical"])
        return 5;
    else if ([title isEqualToString:@"Offroad by ZLZK"])
        return 6;
    else if ([title isEqualToString:@"Desert"])
        return 7;
    else
        return 8;
}

@end
