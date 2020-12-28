//
//  OASRTMPlugin.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASRTMPlugin.h"
#import "OAProducts.h"
#import "OAContourLinesAction.h"
#import "OATerrainAction.h"

#define PLUGIN_ID kInAppId_Addon_Srtm

@implementation OASRTMPlugin

+ (NSString *) getId
{
    return PLUGIN_ID;
}

- (NSString *) getName
{
    return OALocalizedString(@"product_title_srtm");
}

- (NSArray *)getQuickActionTypes
{
    return @[OAContourLinesAction.TYPE, OATerrainAction.TYPE];
}

@end
