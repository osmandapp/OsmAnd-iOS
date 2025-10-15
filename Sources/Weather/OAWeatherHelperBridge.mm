//
//  OAWeatherHelperBridge.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAWeatherHelperBridge.h"
#import "OAWeatherHelper.h"

@implementation OAWeatherHelperBridge

+ (OAWeatherBand *)weatherBandForIndex:(EOAWeatherBand)bandIndex
{
    return [[OAWeatherHelper sharedInstance] getWeatherBand:bandIndex];
}

+ (BOOL)allLayersAreDisabled
{
    return [[OAWeatherHelper sharedInstance] allLayersAreDisabled];
}

@end
